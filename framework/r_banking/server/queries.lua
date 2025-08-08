function GenerateAccountNumber(cb)
    local chars = "0123456789"
    local accountNumber = ""

    for i = 1, 10 do
        local rand = math.random(#chars)
        accountNumber = accountNumber .. string.sub(chars, rand, rand)
    end

    QueryScalar("SELECT COUNT(*) FROM bank_accounts WHERE account_number = ?",
        { accountNumber }, function(result)
            if result and result > 0 then
                return GenerateAccountNumber(cb) -- Si le numéro existe déjà on recommence
            else
                cb(accountNumber)
            end
        end)
end

function HasBankAccount(identifier, cb)
    QueryScalar("SELECT COUNT(*) FROM bank_account_owners WHERE owner_identifier = ?", { identifier },
        function(result)
            cb(result and result > 0)
        end)
end

function GetPlayerAccount(identifier, cb)
    local query = [[
        SELECT ba.*, bao.permission_level
        FROM bank_accounts ba
        INNER JOIN bank_account_owners bao ON ba.id = bao.account_id
        WHERE bao.owner_identifier = ? AND ba.account_type = 'personal'
        ORDER BY bao.permission_level = 'owner'
        DESC LIMIT 1
    ]]

    QuerySingle(query, { identifier }, cb)
end

function GetPlayerAccounts(identifier, cb)
    local query = [[
        SELECT ba.*, bao.permission_level
        FROM bank_accounts ba
        INNER JOIN bank_account_owners bao ON ba.id = bao.account_id
        WHERE bao.owner_identifier = ? AND ba.is_active = 1
        ORDER BY ba.account_type, bao.permission_level = 'owner' DESC
    ]]

    QuerySingle(query, { identifier }, function(result)
        cb(result or {})
    end)
end

function GetAccountByNumber(accountNumber, cb)
    QuerySingle("SELECT * FROM bank_accounts WHERE account_number = ? AND is_active = 1",
        { accountNumber }, cb)
end

function HasAccountPermission(identifier, accountId, cb)
    local query = "SELECT permission_level FROM bank_account_owners WHERE owner_identifier = ? AND account_id = ?"
    QuerySingle(query, { identifier, accountId }, function(result)
        cb(result ~= nil, result and result.permission_level or nil)
    end)
end

function CreateBankAccount(identifier, accountType, cb)
    local source = source
    accountType = accountType or 'checking'

    HasBankAccount(identifier, function(hasBankAccount)
        if (hasBankAccount) then
            TriggerEvent('r_banking:server:showNotification', source, "Vous avez déjà un compte bancaire", "error")
            return
        end

        GenerateAccountNumber(function(accountNumber)
            local insertAccountQuery = [[
                INSERT INTO bank_accounts (account_number, account_name, account_type, balance, is_active)
                VALUES (?, ?, ?, 1000, 1)
            ]]

            local accountName = "Compte " ..
                (accountType == 'checking' and 'personnel' or 'entreprise')

            Insert(insertAccountQuery, { accountNumber, accountName, accountType }, function(accountId)
                if accountId then
                    local insertOwnerQuery = [[
                        INSERT INTO bank_account_owners (account_id, owner_identifier, permission_level)
                        VALUES (?, ?, 'owner')
                    ]]

                    Execute(insertOwnerQuery, { accountId, identifier }, function(success)
                        if success then
                            local accountData = {
                                id = accountId,
                                account_number = accountNumber,
                                account_name = accountName,
                                account_type = accountType,
                                balance = 0,
                                permission_level = 'owner'
                            }
                            cb(true, accountData)
                        else
                            TriggerEvent('r_banking:server:showNotification', source,
                                "Erreur lors de l'ajout du propriétaire du compte", "error")
                            cb(false, nil)
                        end
                    end)
                else
                    TriggerEvent('r_banking:server:showNotification', source, "Erreur lors de la création du compte",
                        "error")
                    cb(false, nil)
                end
            end)
        end)
    end)
end

function GetAccountBalance(accountNumber, cb)
    QueryScalar("SELECT balance FROM bank_accounts WHERE account_number = ? AND is_active = 1",
        { accountNumber }, cb)
end

function DepositMoney(source, accountNumber, amount, description, performedBy, cb)
    local playerIdentifier = GetPlayerIdentifier(source, 0)

    GetAccountByNumber(accountNumber, function(account)
        if not account then
            TriggerEvent('r_banking:server:showNotification', source, "Compte introuvable", "error")
            cb(false, nil)
            return
        end

        local inventoryResult = Query("SELECT * FROM inventories WHERE identifier = ? AND item = 'money'",
            { playerIdentifier })

        if not inventoryResult or #inventoryResult == 0 then
            TriggerEvent('r_banking:server:showNotification', source, "Vous n'avez pas d'argent liquide", 'error')
            cb(false, nil)
            return
        end

        local currentMoney = inventoryResult[1].count

        if currentMoney < amount then
            TriggerEvent('r_banking:server:showNotification', source, "Vous n'avez pas assez d'argent liquide", 'error')
            cb(false, nil)
            return
        end

        local newBalance = account.balance + amount
        local newMoneyCount = currentMoney - amount

        local queries = {
            {
                query = "UPDATE bank_accounts SET balance = ? WHERE id = ?",
                values = { newBalance, account.id }
            },
            {
                query = [[
                    INSERT INTO bank_transactions (account_id, transaction_type, amount, balance_after, description, performed_by)
                    VALUES (?, 'deposit', ?, ?, ?, ?)
                ]],
                values = { account.id, amount, newBalance, description, performedBy }
            }
        }

        if newMoneyCount > 0 then
            -- On met à jour le count
            table.insert(queries, {
                query = "UPDATE inventories SET count = ? WHERE identifier = ? AND item = 'money'",
                values = { newMoneyCount, playerIdentifier }
            })
        else
            -- On supprime l'item de l'inventaire
            table.insert(queries, {
                query = "DELETE FROM inventories WHERE identifier = ? AND item = 'money'",
                values = { playerIdentifier }
            })
        end

        Transaction(queries, function(success)
            if success then
                TriggerEvent('r_banking:server:showNotification', source, "Dépôt effectué avec succès", "success")
                cb(true, newBalance)
            else
                TriggerEvent('r_banking:server:showNotification', source, "Erreur lors du dépot", "error")
                cb(false, nil)
            end
        end)
    end)
end

function WithdrawMoney(accountNumber, amount, description, performedBy, cb)
    local source = source
    local playerIdentifier = GetPlayerIdentifier(source, 0)

    GetAccountByNumber(accountNumber, function(account)
        if not account then
            TriggerEvent('r_banking:server:showNotification', source, "Compte introuvable", "error")
            cb(false, nil)
            return
        end

        if tonumber(account.balance) < amount then
            TriggerEvent('r_banking:server:showNotification', source, "Fonds insuffisants", "error")
            cb(false, nil)
            return
        end

        local newBalance = account.balance - amount

        local inventoryResult = Query("SELECT * FROM inventories WHERE identifier = ? AND item = 'money'",
            { playerIdentifier })

        local queries = {
            {
                query = "UPDATE bank_accounts SET balance = ? WHERE id = ?",
                values = { newBalance, account.id }
            },
            {
                query = [[
                    INSERT INTO bank_transactions (account_id, transaction_type, amount, balance_after, description, performed_by)
                    VALUES (?, 'withdraw', ?, ?, ?, ?)
                ]],
                values = { account.id, amount, newBalance, description, performedBy }
            }
        }

        if inventoryResult and #inventoryResult > 0 then
            -- Met à jour le count de l'item
            local currentCount = inventoryResult[1].count
            local newCount = currentCount + amount

            table.insert(queries, {
                query = "UPDATE inventories SET count = ? WHERE identifier = ? AND item  = 'money'",
                values = { newCount, playerIdentifier }
            })
        else
            -- Créé l'item
            local freeSlot = GetFreeInventorySlot(playerIdentifier)

            if not freeSlot then
                TriggerEvent('r_banking:server:showNotification', source, "Inventaire plein", "error")
                cb(false, nil)
                return
            end

            table.insert(queries, {
                query = "INSERT INTO inventories (identifier, item, count, slot) VALUES (?, ?, ?, ?)",
                values = { playerIdentifier, 'money', amount, freeSlot }
            })
        end

        Transaction(queries, function(success)
            if success then
                TriggerEvent('r_banking:server:showNotification', source, "Retrait effectué avec succès", "success")
                cb(true, newBalance)
            else
                TriggerEvent('r_banking:server:showNotification', source, "Erreur lors du retrait", "error")
                cb(false, nil)
            end
        end)
    end)
end

function TransferMoney(fromAccountNumber, toAccountNumber, amount, description, performedBy, cb)
    local source = source

    GetAccountByNumber(fromAccountNumber, function(fromAccount)
        if not fromAccount then
            TriggerEvent('r_banking:server:showNotification', source, "Compte introuvable", "error")
            cb(false, nil)
            return
        end

        if fromAccount.balance < amount then
            TriggerEvent('r_banking:server:showNotification', source, "Fonds insuffisants", "error")
            cb(false, nil)
            return
        end

        GetAccountByNumber(toAccountNumber, function(toAccount)
            local source = source

            if not toAccount then
                TriggerEvent('r_banking:server:showNotification', source, "Compte destinataire introuvable", "error")
                cb(false, nil)
                return
            end

            local newFromBalance = fromAccount.balance - amount
            local newToBalance = toAccount.balance + amount

            local queries = {
                {
                    query = "UPDATE bank_accounts SET balance = ? WHERE id = ?",
                    values = { newFromBalance, fromAccount.id }
                },
                {
                    query = "UPDATE bank_accounts SET balance = ? WHERE id = ?",
                    values = { newToBalance, toAccount.id }
                },
                {
                    query = [[
                        INSERT INTO bank_transactions (account_id, transaction_type, amount, balance_after, description, target_account_id, performed_by)
                        VALUES (?, 'transfer_out', ?, ?, ?, ?, ?)
                    ]],
                    values = { fromAccount.id, amount, newFromBalance, description, toAccount.id, performedBy }
                },
                {
                    query = [[
                        INSERT INTO bank_transactions (account_id, transaction_type, amount, balance_after, description, target_account_id, performed_by)
                        VALUES (?, 'transfer_in', ?, ?, ?, ?, ?)
                    ]],
                    values = { toAccount.id, amount, newToBalance, description, fromAccount.id, performedBy }
                }
            }

            Transaction(queries, function(success)
                if success then
                    TriggerEvent('r_banking:server:showNotification', source, "Transfert effectué avec succès", "success")
                    cb(true, newFromBalance, newToBalance)
                else
                    TriggerEvent('r_banking:server:showNotification', source, "Erreur lors du transfert", "error")
                    cb(false)
                end
            end)
        end)
    end)
end

function GetTransactionHistory(accountNumber, limit, offset, cb)
    limit = limit or 50
    offset = offset or 0

    GetAccountByNumber(accountNumber, function(account)
        if not account then
            cb({})
            return
        end

        local query = [[
            SELECT bt.*, ba_target.account_number as target_account_number
            FROM bank_transactions bt
            LEFT JOIN bank_accounts ba_target ON bt.target_account_id = ba_target.id
            WHERE bt.account_id = ?
            ORDER BY bt.created_at DESC
            LIMIT ? OFFSET ?
        ]]

        Query(query, { account.id, limit, offset }, function(result)
            cb(result or {})
        end)
    end)
end

function GetPlayerBankingData(identifier, cb)
    -- D'abord récupérer tous les comptes du joueur
    local query = [[
        SELECT ba.*, bao.permission_level
        FROM bank_accounts ba
        INNER JOIN bank_account_owners bao ON ba.id = bao.account_id
        WHERE bao.owner_identifier = ? AND ba.is_active = 1
        ORDER BY ba.account_type, bao.permission_level = 'owner' DESC
    ]]

    Query(query, { identifier }, function(accounts)
        if not accounts or #accounts == 0 then
            -- Pas de comptes trouvés
            cb({
                accounts = {},
                transactions = {}
            })
            return
        end

        -- Récupère les transactions récentes de tous les comptes
        local allTransactions = {}
        local accountsProcessed = 0
        local totalAccounts = #accounts

        for _, account in pairs(accounts) do
            local transactionQuery = [[
                SELECT bt.*, ba_target.account_number as target_account_number,
                       ? as source_account_number
                FROM bank_transactions bt
                LEFT JOIN bank_accounts ba_target ON bt.target_account_id = ba_target.id
                WHERE bt.account_id = ?
                ORDER BY bt.created_at DESC
                LIMIT 20
            ]]

            Query(transactionQuery, { account.account_number, account.id }, function(transactions)
                -- Ajoute les transactions à la liste globale
                if transactions and #transactions > 0 then
                    for _, transaction in pairs(transactions) do
                        table.insert(allTransactions, transaction)
                    end
                end

                accountsProcessed = accountsProcessed + 1

                -- Quand tous les comptes ont été traités
                if accountsProcessed >= totalAccounts then
                    -- Trie les transactions par date (plus récentes en premier)
                    table.sort(allTransactions, function(a, b)
                        return a.created_at > b.created_at
                    end)

                    -- Limite à 50 transactions les plus récentes
                    local recentTransactions = {}
                    for i = 1, math.min(50, #allTransactions) do
                        table.insert(recentTransactions, allTransactions[i])
                    end

                    cb({
                        accounts = accounts,
                        transactions = recentTransactions
                    })
                end
            end)
        end
    end)
end
