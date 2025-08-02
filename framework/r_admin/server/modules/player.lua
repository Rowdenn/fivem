local metabolism = exports['r_metabolism']

function CheckIfPlayerExists(target)
    if not target or not GetPlayerPed(target) then
        TriggerClientEvent('r_admin:server:showNotification', source, 'Joueur introuvable', 'error')
        return
    end
end

RegisterServerEvent('r_admin:getPlayersList')
AddEventHandler('r_admin:getPlayersList', function()
    local players = {}
    local allPlayers = GetPlayers()

    for _, playerId in ipairs(allPlayers) do
        local playerName = GetPlayerName(playerId)
        if playerName then
            table.insert(players, {
                id = tonumber(playerId),
                name = playerName,
            })
        end
    end

    TriggerClientEvent('r_admin:receivePlayersList', source, players)
end)

RegisterServerEvent('r_admin:bringPlayer')
AddEventHandler('r_admin:bringPlayer', function(targetServerId, adminCoords, adminHeading)
    local source = source

    if not HasPermissionServer(source, 'bring') then
        return
    end

    local target = tonumber(targetServerId)
    CheckIfPlayerExists(target)

    local distance = 2.0
    local radians = math.rad(adminHeading)

    local teleportCoords = {
        x = adminCoords.x - math.sin(radians) * distance,
        y = adminCoords.y + math.cos(radians) * distance,
        z = adminCoords.z + 1.0
    }

    TriggerClientEvent('r_admin:teleportPlayer', target, teleportCoords)

    local targetName = GetPlayerName(target)
    local adminName = GetPlayerName(source)

    TriggerEvent('r_admin:server:showNotification', source, 'Joueur ' .. targetName .. ' téléporté vers vous', 'success')
    TriggerEvent('r_admin:server:showNotification', target, 'Vous avez été téléporté par ' .. adminName, 'info')
end)

RegisterServerEvent('r_admin:goToPlayer')
AddEventHandler('r_admin:goToPlayer', function(targetServerId)
    local source = source

    if not HasPermissionServer(source, 'goto') then
        return
    end

    local target = tonumber(targetServerId)
    CheckIfPlayerExists(target)

    local targetCoords = GetEntityCoords(GetPlayerPed(target))

    local teleportCoords = {
        x = targetCoords.x + 2.0,
        y = targetCoords.y + 2.0,
        z = targetCoords.z + 1.0
    }

    local targetName = GetPlayerName(target)

    TriggerClientEvent('r_admin:teleportPlayer', source, teleportCoords)
    TriggerEvent('r_admin:server:showNotification', source, 'Téléporté vers ' .. targetName, 'success')
end)


RegisterServerEvent('r_admin:feedPlayer')
AddEventHandler('r_admin:feedPlayer', function(targetServerId)
    local source = source

    if not HasPermissionServer(source, 'feed') then
        return
    end

    local target = tonumber(targetServerId)
    CheckIfPlayerExists(target)

    local targetName = GetPlayerName(target)
    local playerMetabolism = metabolism:getPlayerMetabolism(target)

    if playerMetabolism then
        metabolism:addHunger(target, (100 - playerMetabolism.hunger))
        metabolism:addThirst(target, (100 - playerMetabolism.thirst))

        TriggerEvent('r_admin:server:showNotification', source, 'Vous avez nourri ' .. targetName, 'success')
        TriggerEvent('r_admin:server:showNotification', target, 'Vous avez été nourri', 'success')
    end
end)

RegisterServerEvent('r_admin:healPlayer')
AddEventHandler('r_admin:healPlayer', function(targetServerId)
    local source = source

    if not HasPermissionServer(source, 'heal') then
        return
    end

    local target = tonumber(targetServerId)
    CheckIfPlayerExists(target)

    local targetName = GetPlayerName(target)

    TriggerClientEvent('r_admin:setPlayerHealth', source)
    TriggerEvent('r_admin:server:showNotification', source, 'Vous avez soigné ' .. targetName, 'success')
    TriggerEvent('r_admin:server:showNotification', target, 'Vous avez été soigné', 'success')
end)
