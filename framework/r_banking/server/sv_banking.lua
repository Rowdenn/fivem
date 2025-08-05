local playerBankData = {}

local function ValidateAmount(amount)
    if not amount or type(amount) ~= 'number' then
        TriggerEvent('r_banking:server:showNotification', source, "Montant invalide", "error")
        return false
    end

    if amount <= 0 then
        TriggerEvent('r_banking:server:showNotification', source, "Le montant doit être supérieur à 0", "error")
        return false
    end

    if amount > 999999999 then
        TriggerEvent('r_banking:server:showNotification', source, "Le montant est trop élevé ça va pas ou quoi", "error")
        return false
    end

    if math.floor(amount * 100) ~= amount * 100 then
        TriggerEvent('r_banking:server:showNotification', source, "Le montant ne peut pas avoir plus de 2 décimales",
            "error")
        return false
    end

    return true
end

local function ClearPlayerCache(source)
    local identifier = GetPlayerIdentifier(source, 0)
    if identifier then
        playerBankData[identifier] = nil
    end
end

function NotifyAccountOwner(accountNumber, message)
    QuerySingle('SELECT owner_identifier FROM bank_accounts WHERE account_number = ?',
        { accountNumber }, function(result)
            if result then
                local players = GetPlayers()
                for _, playerId in pairs(players) do
                    local playerIdentifier = GetPlayerIdentifier(playerId, 0)
                    if playerIdentifier == result.owner_identifier then
                        TriggerEvent('r_banking:server:showNotification', tonumber(playerId), message, 'info')
                        break
                    end
                end
            end
        end)
end

function GetPlayerMoney(source)
    local identifier = GetPlayerIdentifier(source, 0)
    if not identifier then return 0 end

    print(identifier)

    local result = QuerySingle("SELECT count FROM inventories WHERE identifier = ? AND item = 'money'", { identifier })
    if result then
        return result.count
    else
        return 0
    end
end

RegisterNetEvent('r_banking:client:showNotification', function(message, type)
    local player = source
    ShowNotificationToPlayer(player, {
        message = message,
        type = type,
        duration = 5000
    })
end)

RegisterNetEvent('r_banking:server:showNotification', function(player, message, type)
    ShowNotificationToPlayer(player, {
        message = message,
        type = type,
        duration = 5000
    })
end)

RegisterNetEvent('r_banking:openUI', function()
    local source = source

    print("Demande de l'ouverture de l'interface")

    if not source or source == 0 then
        return
    end

    GetFullname(source, function(playerData)
        if not playerData then
            TriggerEvent('r_banking:server:showNotification', source, "Impossible de récupérer vos informations", "error")
            return
        end

        print("Récupération des données bancaires pour:", playerData.identifier)

        GetPlayerBankingData(playerData.identifier, function(bankingData)
            print("Données bancaires récupérées:", json.encode(bankingData))

            -- Si le joueur n'a pas de comptes, en créer un
            if not bankingData.accounts or #bankingData.accounts == 0 then
                print("Aucun compte trouvé, création d'un nouveau compte")
                CreateBankAccount(playerData.identifier, 'checking', function(success, accountData)
                    if success then
                        TriggerClientEvent('r_banking:openBankMenu', source, {
                            playerData = playerData,
                            accounts = { accountData },
                            transactions = {}
                        })
                    else
                        TriggerEvent('r_banking:server:showNotification', source,
                            "Impossible de créer votre compte bancaire", "error")
                    end
                end)
            else
                print("Envoi des données complètes au client")

                playerBankData[playerData.identifier] = {
                    playerData = playerData,
                    accounts = bankingData.accounts,
                    transactions = bankingData.transactions,
                    lastUpdate = GetGameTimer()
                }

                TriggerClientEvent('r_banking:openBankMenu', source, {
                    playerData = playerData,
                    accounts = bankingData.accounts,
                    transactions = bankingData.transactions
                })
            end
        end)
    end)
end)

RegisterNetEvent('r_banking:createAccount', function(accountType)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    accountType = accountType or 'checking'

    if accountType ~= 'checking' and accountType ~= 'savings' then
        TriggerEvent('r_banking:server:showNotification', source, "Type de compte invalide")
        return
    end

    CreateBankAccount(identifier, accountType, function(success, accountData, message)
        if success then
            ClearPlayerCache(source)
            TriggerEvent('r_banking:server:showNotification', source, "Compte créé avec succès", "success")
            TriggerClientEvent('r_banking:accountCreated', source, accountData)
        else
            TriggerEvent('r_banking:server:showNotification', source, message or "Impossible de créer le compte",
                "success")
        end
    end)
end)

RegisterNetEvent('r_banking:getBalance', function(accountNumber)
    local source = source

    if not accountNumber then
        TriggerEvent('r_banking:server:showNotification', source, "Numéro de compte manquant", "error")
        return
    end

    GetAccountBalance(accountNumber, function(balance)
        if balance then
            TriggerClientEvent('r_banking:balanceUpdated', source, accountNumber, balance)
        else
            TriggerEvent('r_banking:server:showNotification', source, "Compte introuvable", "error")
        end
    end)
end)

RegisterNetEvent('r_banking:deposit', function(accountNumber, amount, description)
    local source = source

    print("Demande de deposit reçue")

    local isValidAmount, amountError = ValidateAmount(amount)
    if not isValidAmount then
        TriggerClientEvent('r_banking:server:showNotification', source, amountError, "error")
        return
    end

    if not accountNumber then
        TriggerClientEvent('r_banking:server:showNotification', source, "Numéro de compte manquant", "error")
        return
    end

    description = description or "Dépôt en espèces"

    local playerMoney = GetPlayerMoney(source)
    print(playerMoney)
    if not playerMoney or playerMoney < amount then
        TriggerClientEvent('r_banking:server:showNotification', source, "Vous n'avez pas assez d'argent liquide", "error")
        return
    end

    DepositMoney(source, accountNumber, amount, description, GetPlayerIdentifier(source, 0),
        function(success)
            if success then
                ClearPlayerCache(source)
                TriggerEvent('r_banking:refreshAccountData', source)
            end
        end)
end)

RegisterNetEvent('r_banking:withdraw', function(accountNumber, amount, description)
    local source = source

    local isValidAmount, amountError = ValidateAmount(amount)
    if not isValidAmount then
        TriggerClientEvent('r_banking:server:showNotification', source, amountError, "error")
        return
    end

    if not accountNumber then
        TriggerClientEvent('r_banking:server:showNotification', source, "Numéro de compte manquant", "error")
        return
    end

    description = description or "Retrait en espèces"

    WithdrawMoney(accountNumber, amount, description, GetPlayerIdentifier(source, 0),
        function(success)
            if success then
                ClearPlayerCache(source)
                TriggerEvent('r_banking:refreshAccountData', source)
            end
        end)
end)

RegisterNetEvent('r_banking:transfer', function(fromAccountNumber, toAccountNumber, amount, description)
    local source = source

    local isValidAmount, amountError = ValidateAmount(amount)
    if not isValidAmount then
        TriggerClientEvent('r_banking:server:showNotification', source, amountError, "error")
        return
    end

    if not fromAccountNumber or not toAccountNumber then
        TriggerClientEvent('r_banking:server:showNotification', source, "Numéro de compte manquant", "error")
        return
    end

    if fromAccountNumber == toAccountNumber then
        TriggerClientEvent('r_banking:server:showNotification', source, "Impossible de transférer vers le même compte",
            "error")
        return
    end

    description = description or "Retrait en espèces"

    GetAccountBalance(toAccountNumber, function(targetBalance)
        if not targetBalance then
            TriggerEvent('r_banking:server:showNotification', source, "Compte destinataire introuvable", "error")
            return
        end

        TransferMoney(fromAccountNumber, toAccountNumber, amount, description, GetPlayerIdentifier(source, 0),
            function(success, message, newFromBalance, newToBalance)
                if success then
                    ClearPlayerCache(source)

                    TriggerEvent('r_banking:server:showNotification', source, "Virement effectué avec succès", "success")
                    TriggerEvent('r_banking:refreshAccountData', source)

                    NotifyAccountOwner(toAccountNumber, 'Virement reçu de ' .. amount .. '$ - ' .. description)
                end
            end)
    end)
end)

RegisterNetEvent('r_banking:getTransactions', function(accountNumber, page, limit, transactionType)
    local source = source

    print("Server getTransactions - Account:", accountNumber, "Type:", transactionType, "Page:", page, "Limit:", limit)

    if not accountNumber then
        TriggerClientEvent('r_banking:showNotification', source, 'error', 'Numéro de compte manquant')
        return
    end

    page = page or 1
    limit = limit or 10
    local offset = (page - 1) * limit

    local whereClause = 'WHERE bank_transactions.account_id = (SELECT id FROM bank_accounts WHERE account_number = ?)'
    local params = { accountNumber }

    if transactionType and transactionType ~= 'all' and transactionType ~= '' then
        whereClause = whereClause .. ' AND bank_transactions.transaction_type = ?'
        table.insert(params, transactionType)
    end

    local query = string.format([[
        SELECT bank_transactions.transaction_type, bank_transactions.amount, bank_transactions.balance_after,
               bank_transactions.description, target.account_number as target_account_id, bank_transactions.created_at
        FROM bank_transactions
        LEFT JOIN bank_accounts target ON bank_transactions.target_account_id = target.id
        %s
        ORDER BY bank_transactions.created_at DESC
        LIMIT %d OFFSET %d
    ]], whereClause, limit, offset)

    Query(query, params, function(transactions)
        if transactions then
            local countQuery = string.format([[
                SELECT COUNT(*) as total
                FROM bank_transactions
                LEFT JOIN bank_accounts target ON bank_transactions.target_account_id = target.id
                %s
            ]], whereClause)

            QueryScalar(countQuery, params, function(total)
                local totalPages = math.ceil((total or 0) / limit)

                TriggerClientEvent('r_banking:transactionsLoaded', source, {
                    transactions = transactions,
                    page = page,
                    totalPages = totalPages,
                    total = total or 0
                })
            end)
        else
            TriggerEvent('r_banking:server:showNotification', source, "Erreur lors du chargement des transactions",
                "error")
        end
    end)
end)

RegisterNetEvent('r_banking:checkAccount', function(accountNumber)
    local source = source

    if not accountNumber then
        TriggerClientEvent('r_banking:accountCheckResult', source, false, 'Numéro de compte manquant')
        return
    end

    -- Vérifie la longueur et le format du numéro de compte
    if string.len(accountNumber) ~= 10 or not string.match(accountNumber, '^%d+$') then
        TriggerClientEvent('r_banking:accountCheckResult', source, false, 'Format de numéro de compte invalide')
        return
    end

    QuerySingle('SELECT owner_name FROM bank_accounts WHERE account_number = ?', { accountNumber },
        function(result)
            if result then
                TriggerClientEvent('r_banking:accountCheckResult', source, true, 'Compte trouvé', result.owner_name)
            else
                TriggerClientEvent('r_banking:accountCheckResult', source, false, 'Compte introuvable')
            end
        end)
end)

RegisterNetEvent('r_banking:getAccounts', function()
    local source = source

    GetFullname(source, function(playerData)
        if not playerData then
            TriggerEvent('r_banking:server:showNotification', source, "Impossible de récupérer vos informations", "error")
            return
        end

        HasBankAccount(playerData.identifier, function(hasAccount, accounts)
            if hasAccount then
                TriggerClientEvent('r_banking:accountsLoaded', source, accounts)
            else
                TriggerClientEvent('r_banking:accountsLoaded', source, {})
            end
        end)
    end)
end)

RegisterNetEvent('r_banking:refreshAccountData', function(targetSource)
    local source = targetSource or source

    GetFullname(source, function(playerData)
        if not playerData then
            TriggerEvent('r_banking:server:showNotification', source, "Impossible de récupérer vos informations", "error")
            return
        end

        GetPlayerBankingData(playerData.identifier, function(bankingData)
            if bankingData and bankingData.accounts then
                playerBankData[playerData.identifier] = {
                    playerData = playerData,
                    accounts = bankingData.accounts,
                    transactions = bankingData.transactions,
                    lastUpdate = GetGameTimer()
                }

                TriggerClientEvent('r_banking:updateAccountData', source, {
                    accounts = bankingData.accounts,
                    transactions = bankingData.transactions,
                    playerName = playerData.fullname
                })
            end
        end)
    end)
end)

RegisterNetEvent('r_banking:closeUI', function()
    local source = source
    ClearPlayerCache(source)
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    ClearPlayerCache(source)
end)

-- Commande pour test
RegisterCommand('bank', function(source, args)
    if source == 0 then return end

    TriggerEvent('r_banking:openUI', source)
end, false)


RegisterCommand('createbankaccount', function(source, args)
    if source ~= 0 then
        if not exports['r_admin']:HasPermissionServer(source, 'create_bank_account') then
            return
        end
    end

    if not args[1] then
        TriggerEvent('r_banking:server:showNotification', source, "Usage: /createbankaccount <player_id> [account_type]",
            "info")
        return
    end

    local targetId = tonumber(args[1])
    local accountType = args[2] or 'checking'

    if not targetId or not GetPlayerName(targetId) then
        TriggerEvent('r_banking:server:showNotification', source, "Joueur introuvable", "error")
        return
    end

    CreateBankAccount(targetId, function(success, accountData, message)
        if success then
            TriggerEvent('r_banking:server:showNotification', source,
                'Compte bancaire créé pour ' .. GetPlayerName(targetId), "success")
            TriggerEvent('r_banking:server:showNotification', targetId, 'Un compte bancaire vous a été créé', 'success')
        else
            TriggerEvent('r_banking:server:showNotification', source,
                'Erreur lors de la création du compte: ' .. (message or 'Erreur inconnue'), "error")
        end
    end, accountType)
end, true)

RegisterCommand('addbankmoney', function(source, args)
    local source = source

    if source ~= 0 then
        if not exports['r_admin']:HasPermissionServer(source, 'addbankmoney') then
            return
        end
    end

    if not args[1] or not args[2] then
        print('Usage: /addbankmoney <account_number> <amount> [description]')
        return
    end

    local accountNumber = args[1]
    local amount = tonumber(args[2])
    local description = args[3] or 'Ajout administrateur'

    if not amount or amount <= 0 then
        print('Montant invalide')
        return
    end

    DepositMoney(source, accountNumber, amount, description, 'system', function(success, newBalance, message)
        if success then
            print('Argent ajouté au compte ' .. accountNumber .. ': ' .. amount .. '$')
            NotifyAccountOwner(accountNumber, 'Votre compte a été crédité de ' .. amount .. '$')
        else
            print('Erreur: ' .. (message or 'Erreur inconnue'))
        end
    end)
end, true)
