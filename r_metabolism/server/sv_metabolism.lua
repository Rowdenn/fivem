local Framework = exports['framework']:GetFramework()
local playerMetabolism = {}

RegisterServerEvent('r_metabolism:playerLoaded')
AddEventHandler('r_metabolism:playerLoaded', function()
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)

    local result = Framework.Database:Query('SELECT hunger, thirst FROM users WHERE identifier = ?', {
        identifier
    })

    if source ~= nil then
        playerMetabolism[source] = {
            hunger = result[1].hunger or 100,
            thirst = result[1].thirst or 100
        }
    end

    TriggerClientEvent('r_metabolism:updateValues', source, result)
end)

-- Met à jour les valeurs de métabolisme toutes les 30 secondes
Citizen.CreateThread(function() 
    while true do
        Citizen.Wait(30000) -- Update toutes les 30 secondes

        for playerId, data in pairs(playerMetabolism) do
            if GetPlayerPing(playerId) > 0 then
                data.hunger = math.max(0, data.hunger - 1)
                data.thirst = math.max(0, data.thirst - 1)

                TriggerClientEvent('r_metabolism:updateValues', playerId, data)

                if data.hunger <= 10 or data.thirst <= 10 then
                    TriggerClientEvent('r_metabolism:lowValues', playerId)
                end

                Framework.Database:Execute('UPDATE users SET hunger = ?, thirst = ? WHERE identifier = ?', {
                    data.hunger,
                    data.thirst,
                    GetPlayerIdentifier(playerId, 0)
                })
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

AddEventHandler('playerDropped', function(reason)
    local source = source

    if source ~= nil then
        if playerMetabolism[source] then
            playerMetabolism[source] = nil
        end
    end
    
end)

exports('addHunger', function(playerId, amount)
    TriggerEvent('r_metabolism:updateValue', 'hunger', amount)
end)

exports('addThirst', function(playerId, amount)
    TriggerEvent('r_metabolism:updateValue', 'thirst', amount)
end)