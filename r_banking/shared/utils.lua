local Framework = exports['framework']:GetFramework()

RegisterServerEvent('r_admin:client:showNotification')
AddEventHandler('r_admin:client:showNotification', function(message, type)
    local player = source
    exports['r_notify']:ShowNotificationToPlayer(player, {
        message = message,
        type = type,
        duration = 5000
    })
end)

RegisterServerEvent('r_admin:server:showNotification')
AddEventHandler('r_admin:server:showNotification', function(player, message, type)
    exports['r_notify']:ShowNotificationToPlayer(player, {
        message = message,
        type = type,
        duration = 5000
    })
end)

function GenerateAccountNumber(cb)
    local chars = "0123456789"
    local accountNumber = ""

    for i = 1, 10 do
        local rand = math.random(#chars)
        accountNumber = accountNumber .. string.sub(chars, rand, rand)
    end

    Framework.Database:QueryScalar("SELECT COUNT(*) FROM bank_accounts WHERE account_number ?",
        { accountNumber }, function(result)
            if result and result > 0 then
                return GenerateAccountNumber(cb) -- Si le numéro existe déjà on recommence
            else
                cb(accountNumber)
            end
        end)
end

function HasBankAccount(identifier, cb)
    Framework.Database:QueryScalar("SELECT COUNT(*) FROM bank_accounts_owners WHERE owner_identifier = ?", { identifier },
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

    Framework.Database:QuerySingle(query, { identifier }, cb)
end

function GetPlayerAccounts(identifier, cb)
    local query = [[
        SELECT ba.*, bao.permission_level
        FROM bank_accounts ba
        INNER JOIN bank_account_owners bao ON ba.id = bao.account_id
        WHERE bao.owner_identifier = ? AND ba.is_active = 1
        ORDER BY ba.account_type, bao.permission_level = 'owner' DESC
    ]]

    Framework.Database:QuerySingle(query, { identifier }, function(result)
        cb(result or {})
    end)
end

function GetAccountByNumber(accountNumber, cb)
    Framework.Database:QuerySingle("SELECT * FROM bank_accounts WHERE account_number = ? AND is_active = 1",
        { accountNumber }, cb)
end

function HasAccountPermission(identifier, accountId, cb)
    local query = "SELECT permission_level FROM bank_accounts_owners WHER owner_identifier = ? AND account_id = ?"
    Framework.Database:QuerySingle(query, { identifier, accountId }, function(result)
        cb(result ~= nil, result and result.permission_level or nil)
    end)
end

function ProcessTransaction(accountId, transactionType, amount, description, performedBy, targetAccountId, cb)
    local source = source
    Framework.Database:QueryScalar("SELECT balance FROM bank_accounts WHERE id = ?", { accountId },
        function(currentBalance)
            if not currentBalance then
                TriggerEvent('r_admin:server:showNotification', source, "Compte introuvable", "error")
                cb(false)
            end

            local newBalance = currentBalance

            if transactionType == 'withdraw' or transactionType == 'transfer_out' then
                if currentBalance < amount then
                    TriggerEvent('r_admin:server:showNotification', source, "Fonds insuffisants", "error")
                    cb(false)
                    return
                end

                newBalance = currentBalance - amount
            elseif transactionType == 'deposit' or transactionType == 'transfer_in' then
                newBalance = currentBalance + amount
            end

            local queries = {
                {
                    query = "UPDATE bank_accounts SET balance = ? WHERE id = ?",
                    values = { newBalance, accountId }
                },
                {
                    query = [[
                    INSERT INTO bank_transactions
                    (account_id, transaction_type, amount, balance_after, description, target_account_id, performed_by)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ]],
                    values = { accountId, transactionType, amount, newBalance, description, targetAccountId, performedBy }
                }
            }

            Framework.Database:Transaction(queries, function(success)
                if success then
                    TriggerEvent('r_admin:server:showNotification', source,
                        "Vous avez transféré " .. amount .. " au compte n°" .. targetAccountId, "success")
                    cb(true)
                else
                    TriggerEvent('r_admin:server:showNotification', source, "Erreur lors de la transaction", "error")
                    cb(false)
                end
            end)
        end)
end

function ProcessTransfer(fromAccountId, toAccountId, amount, description, performedBy, cb)
    Framework.Database:QueryScalar("SELECT balance FROM bank_accounts WHERE id = ?", { fromAccountId },
        function(fromBalance)
            if not fromBalance then
                TriggerEvent('r_admin:server:showNotification', source, "Compte source introuvable", "error")
                cb(false)
                return
            end

            if fromBalance < amount then
                TriggerEvent('r_admin:server:showNotification', source, "Fonds insuffisants", "error")
                cb(false)
                return
            end

            Framework.Database:QueryScalar("SELECT balance FROM bank_accounts WHERE id = ?", { toAccountId },
                function(toBalance)
                    if not toBalance then
                        TriggerEvent('r_admin:server:showNotification', source, "Compte destinataire introuvable",
                            "error")
                        cb(false)
                        return
                    end

                    local newFromBalance = fromBalance - amount
                    local newToBalance = toBalance + amount

                    local queries = {
                        {
                            query = "UPDATE bank_accounts SET balance = ? WHERE id = ?",
                            values = { newFromBalance, fromAccountId }
                        },
                        {
                            query = "UPDATE bank_accounts SET balance = ? WHERE id = ?",
                            values = { newToBalance, toAccountId }
                        },
                        {
                            query = [[
                        INSERT INTO bank_transactions
                        (account_id, transaction_type, amount, balance_after, description, target_account_id, performed_by)
                        VALUES (?, 'transfer_out', ?, ?, ?, ?, ?)
                    ]],
                            values = { fromAccountId, amount, newFromBalance, description, toAccountId, performedBy }
                        },
                        {
                            query = [[
                        INSERT INTO bank_transactions
                        (account_id, transaction_type, amount, balance_after, description, target_account_id, performed_by)
                        VALUES (?, 'transfer_in', ?, ?, ?, ?, ?)
                    ]],
                            values = { toAccountId, amount, newFromBalance, description, fromAccountId, performedBy }
                        }
                    }

                    Framework.Database:Transaction(queries, function(success)
                        if success then
                            TriggerEvent('r_admin:server:showNotification', source, "Transfert réussi", "success")
                            cb(true, newFromBalance, newToBalance)
                        else
                            TriggerEvent('r_admin:server:showNotification', source, "Erreur lors du transfert", "error")
                            cb(false)
                        end
                    end)
                end)
        end)
end
