local isNuiOpen         = false
local isNuiLoaded       = false
local currentBankData   = {}
local bankNPCIds        = {}

local currentNearestATM = nil
local ATM_DISTANCE      = 1.0


local function openBankNUI(data)
    if isNuiOpen then return end

    isNuiOpen = true
    SetNuiFocus(true, true)

    if not isNuiLoaded then
        isNuiLoaded = true
        SendNuiMessage(json.encode({
            action = 'loadUI',
            module = 'bank',
            data = data
        }))
    else
        SendNuiMessage(json.encode({
            action = 'updateUI',
            module = 'bank',
            data = {
                action = 'show',
                accounts = data.accounts,
                transactions = data.transactions,
                playerName = data.playerName,
                isATM = data.isATM or false
            }
        }))
    end
end

local function closeBankNUI()
    if not isNuiOpen then return end

    isNuiOpen = false
    SetNuiFocus(false, false)

    SendNuiMessage(json.encode({
        action = 'hideModule',
        module = 'bank',
    }))
end

local function handleBankUIOpen(data)
    if not data then return end


    local uiData = {
        accounts = data.accounts or {},
        transactions = data.transactions or {},
        playerName = (data.playerData and data.playerData.fullname) or data.playerName or GetPlayerName(PlayerId()),
        isATM = data.isATM or false
    }


    currentBankData = data
    openBankNUI(uiData)
end

RegisterAndHandleNetEvent('r_banking:openBankMenu', handleBankUIOpen)

RegisterAndHandleNetEvent('r_banking:openInterface', handleBankUIOpen)

local function createBankNPC()
    local bankerConfigs = {}

    for i, banker in pairs(GlobalConfig.Bank.Bankers) do
        table.insert(bankerConfigs, {
            model = banker.model,
            coords = banker.coords,
            heading = banker.heading,
            name = string.format("Banquier"),
            interactionText = "Appuyez sur E pour parler au banquier",
            onInteract = function()
                TriggerServerEvent('r_banking:createAccount', 'checking')
            end,
            scenario = "WORLD_HUMAN_STAND_IMPATIENT",
            invincible = true,
            freeze = true
        })
    end

    bankNPCIds = CreateMultipleNPC(bankerConfigs)

    print(string.format("%d banquiers créés avec succès", #bankNPCIds))
    return bankNPCIds
end

RegisterAndHandleNetEvent('r_banking:updateAccountData', function(updatedData)
    if not isNuiOpen then return end

    currentBankData = updatedData
    SendNuiMessage(json.encode({
        action = 'updateUI',
        module = 'bank',
        data = updatedData
    }))
end)

RegisterAndHandleNetEvent('r_banking:showNotification', function(message, notifType)
    SendNuiMessage(json.encode({
        action = "updateUI",
        module = 'bank',
        data = {
            action = "showNotification",
            message = message,
            type = notifType or 'info'
        }
    }))
end)

RegisterAndHandleNetEvent('r_banking:resetData', function()
    currentBankData = {}
    if isNuiOpen then
        closeBankNUI()
    end
end)

RegisterAndHandleNetEvent('r_banking:showError', function(message)
    SendNuiMessage(json.encode({
        action = "updateUI",
        module = 'bank',
        data = {
            action = "showError",
            message = message
        }
    }))
end)

RegisterNUICallback("withdraw", function(data, cb)
    print("Demande de withdraw avec la data: ", json.encode(data))

    if not data.accountNumber or not data.amount then
        cb({ success = false, message = "Données invalides" })
        return
    end

    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        cb({ success = false, message = "Montant invalide" })
        return
    end

    TriggerServerEvent('r_banking:withdraw', data.accountNumber, amount, data.description or "Retrait")
end)

RegisterNUICallback("deposit", function(data, cb)
    print("Demande de dépot avec la data: ", json.encode(data))

    if not data.accountNumber or not data.amount then
        cb({ success = false, message = "Données invalides" })
        return
    end

    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        cb({ success = false, message = "Montant invalide" })
        return
    end

    TriggerServerEvent('r_banking:deposit', data.accountNumber, amount, data.description or "Dépôt")
end)

RegisterNUICallback("transfer", function(data, cb)
    print("Demande de transfer avec la data: ", json.encode(data))

    if data.fromAccount == data.toAccount then
        cb({ success = false, message = 'Impossible de transférer vers le même compte' })
        return
    end

    if not data.accountNumber or not data.amount or not data.fromAccount or not data.toAccount then
        cb({ success = false, message = "Données invalides" })
        return
    end

    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        cb({ success = false, message = "Montant invalide" })
        return
    end

    TriggerServerEvent('r_banking:transfer', data.fromAccountNumber, data.toAccountNumber, amount,
        data.description or "Transfert")
end)

RegisterNUICallback('refreshData', function(data, cb)
    TriggerServerEvent('r_banking:refreshAccountData')
    cb('ok')
end)

RegisterNUICallback('closeBank', function(data, cb)
    closeBankNUI()
    cb('ok')
end)

RegisterAndHandleNetEvent('r_banking:transactionsLoaded', function(data)
    print("Client reçu transactionsLoaded:", json.encode(data))

    if not isNuiOpen then
        print("Interface fermée, données ignorées")
        return
    end

    local messageData = {
        action = 'updateUI',
        module = 'bank',
        data = {
            action = 'transactionsLoaded',
            transactions = data.transactions,
            page = data.page,
            totalPages = data.totalPages,
            total = data.total
        }
    }

    print("Envoi vers NUI:", json.encode(messageData))
    SendNuiMessage(json.encode(messageData))
end)

RegisterNUICallback('getTransactions', function(data, cb)
    if not data.accountNumber then
        cb({ success = false, message = "Numéro de compte requis" })
        return
    end

    print("Data du fetch: ", json.encode(data))

    TriggerServerEvent('r_banking:getTransactions', data.accountNumber, data.page or 1, data.limit or 10,
        data.transactionType)
    cb({ success = true })
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearestATM = nil
        local nearestDistance = math.huge

        for _, atm in pairs(GlobalConfig.Bank.ATMs) do
            local distance = #(playerCoords - atm.coords)

            if distance <= ATM_DISTANCE and distance < nearestDistance then
                nearestDistance = distance
                nearestATM = atm
                sleep = 200
            end
        end

        currentNearestATM = nearestATM
        Citizen.Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    local notificationManager = CreateProximityNotificationManager()

    while true do
        local sleep = notificationManager:HandleNotification(
            currentNearestATM,
            "Appuyez sur E pour utiliser le distributeur",
            function()
                TriggerServerEvent('r_banking:openUI')
            end
        )

        Citizen.Wait(sleep)
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        createBankNPC()
    end
end)

RegisterCommand('bank', function()
    TriggerServerEvent('r_banking:openUI')
end, false)
