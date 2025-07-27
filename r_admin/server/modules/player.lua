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
AddEventHandler('r_admin:bringPlayer', function(targetServerId, adminCoords)
    local source = source

    if not HasPermissionServer(source, 'bring') then
        return
    end

    local target = tonumber(targetServerId)
    if not target or not GetPlayerPed(target) then
        TriggerClientEvent('r_admin:showNotification', source, 'Joueur introuvable', 'error')
        return
    end

    local teleportCoords = {
        x = adminCoords.x + 2.0,
        y = adminCoords.y + 2.0,
        z = adminCoords.z + 1.0
    }

    TriggerClientEvent('r_admin:teleportPlayer', target, teleportCoords)

    local targetName = GetPlayerName(target)
    local adminName = GetPlayerName(source)

    TriggerEvent('r_admin:showNotification', source, 'Joueur ' .. targetName .. ' téléporté vers vous', 'success')
    TriggerEvent('r_admin:showNotification', target, 'Vous avez été téléporté par ' .. adminName, 'info')
end)

RegisterServerEvent('r_admin:goToPlayer')
AddEventHandler('r_admin:goToPlayer', function(targetServerId)
    local source = source

    if not HasPermissionServer(source, 'goto') then
        return
    end

    local target = tonumber(targetServerId)
    if not target or not GetPlayerPed(target) then
        TriggerClientEvent('r_admin:showNotification', source, 'Joueur introuvable', 'error')
        return
    end

    local targetCoords = GetEntityCoords(GetPlayerPed(target))

    local teleportCoords = {
        x = targetCoords.x + 2.0,
        y = targetCoords.y + 2.0,
        z = targetCoords.z + 1.0
    }

    local targetName = GetPlayerName(target)

    TriggerClientEvent('r_admin:teleportPlayer', source, teleportCoords)
    TriggerEvent('r_admin:showNotification', source, 'Téléporté vers ', targetName, 'success')
end)
