local Framework = exports['framework']:GetFramework()
local playerMetabolism = {}

local Config = {
    updateInterval = 60000, -- Mise à jour toutes les minutes
    hungerDecrease = 1,
    thirstDecrease = 2,
    warningThreshold = 10
}

RegisterServerEvent('r_metabolism:playerLoaded')
AddEventHandler('r_metabolism:playerLoaded', function()
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)

    if not identifier then return end

    if playerMetabolism[source] then
        TriggerClientEvent('r_metabolism:updateValues', source, playerMetabolism[source])
        return
    end

    Framework.Database:Query('SELECT hunger, thirst FROM users WHERE identifier = ?', {identifier}, function(result)
        if DoesPlayerExist(source) then
            if source ~= nil then
                playerMetabolism[source] = {
                    hunger = (result[1] and result[1].hunger) or 100,
                    thirst = (result[1] and result[1].thirst) or 100,
                    identifier = identifier,
                    isLoaded = true
                }
            end

            TriggerClientEvent('r_metabolism:updateValues', source, playerMetabolism[source])
        end
    end)
end)

-- Met à jour les valeurs de métabolisme toutes les minutes
Citizen.CreateThread(function() 
    while true do
        Citizen.Wait(Config.updateInterval) -- Update toutes les minutes

        for playerId, data in pairs(playerMetabolism) do
            if GetPlayerPing(playerId) > 0 then
                data.hunger = math.max(0, data.hunger - Config.hungerDecrease)
                data.thirst = math.max(0, data.thirst - Config.thirstDecrease)

                if data.hunger == 10 then
                    exports['r_notify']:ShowNotificationToPlayer(playerId, {
                        message = "Vous avez très faim",
                        type = 'error',
                        duration = 5000
                    })
                end
                
                if data.thirst == 10 then
                    exports['r_notify']:ShowNotificationToPlayer(playerId, {
                        message = "Vous avez très soif",
                        type = 'error',
                        duration = 5000
                    })
                end

                TriggerClientEvent('r_metabolism:updateValues', playerId, data)

                if data.hunger <= 10 or data.thirst <= 10 then
                    TriggerClientEvent('r_metabolism:lowValues', playerId)
                end
            else
                playerMetabolism[playerId] = nil
            end
        end
    end
end)

RegisterServerEvent('r_metabolism:updateValue')
AddEventHandler('r_metabolism:updateValue', function(valueType, amount)
    local source = source
    
    if playerMetabolism[source] then
        if valueType == 'hunger' then
            playerMetabolism[source].hunger = math.min(100, math.max(0, playerMetabolism[source].hunger + amount))
        elseif valueType == 'thirst' then
            playerMetabolism[source].thirst = math.min(100, math.max(0, playerMetabolism[source].thirst + amount))
        end

        TriggerClientEvent('r_metabolism:updateValues', source, playerMetabolism[source])
    end
end)

RegisterServerEvent('r_metabolism:setValues')
AddEventHandler('r_metabolism:setValues', function(hunger, thirst)
    local source = source

    if playerMetabolism[source] then
        playerMetabolism[source].hunger = math.min(100, math.max(0, hunger))
        playerMetabolism[source].thirst = math.min(100, math.max(0, thirst))

        TriggerClientEvent('r_metabolism:updateValues', source, playerMetabolism[source])
    end
end)

-- Sauvegarde à la déconnexion du joueur
AddEventHandler('playerDropped', function()
    local source = source

    if source ~= nil then
        if playerMetabolism[source] and playerMetabolism[source].isLoaded then
            local data = playerMetabolism[source]
            Framework.Database:Execute('UPDATE users SET hunger = ?, thirst = ? WHERE identifier = ?', {
                data.hunger,
                data.thirst,
                data.identifier
            })
        end
    end
end)

-- Sauvegarde au restart du serveur
AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() == resource then
        for playerId, data in pairs(playerMetabolism) do
            if data.isLoaded and DoesPlayerExist(playerId) then
                Framework.Database:Execute('UPDATE users SET hunger = ?, thirst = ? WHERE identifier = ?', {
                    data.hunger,
                    data.thirst,
                    data.identifier
                })
            end
        end
    end
end)

exports('addHunger', function(playerId, amount)
    if playerMetabolism[playerId] and playerMetabolism[playerId].isLoaded then
        TriggerEvent('r_metabolism:updateValue', 'hunger', amount)
    end
end)

exports('addThirst', function(playerId, amount)
    if playerMetabolism[playerId] and playerMetabolism[playerId].isLoaded then
        TriggerEvent('r_metabolism:updateValue', 'thirst', amount)
    end
end)

exports('getPlayerMetabolism', function(playerId)
    return playerMetabolism[playerId]
end)