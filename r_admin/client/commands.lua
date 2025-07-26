local playerPermissionLevel = 0

function HasPermissions(requiredLevel)
    print(playerPermissionLevel)
    return playerPermissionLevel >= requiredLevel
end

function RegisterProtectedCommand(commandName, handler)
    RegisterCommand(commandName, function(source, args, rawCommand)
        local requiredLevel = 0

        for permissionLevel, commands in pairs(AdminConfig.CommandsPermissions) do
            for _, command in pairs(commands) do
                if command == commandName then
                    requiredLevel = permissionLevel
                    break
                end
            end
            if requiredLevel > 0 then break end
        end

        if not HasPermissions(requiredLevel) then
            TriggerServerEvent('r_admin:showNotification',
                'Vous ne pouvez pas exécuter cette commande', 'error')
            return
        end

        handler(source, args, rawCommand)
    end, false)
end

RegisterProtectedCommand('tp', function(source, args)
    if #args == 0 then
        TriggerEvent('chat:addMessage', {
            color = { 255, 165, 0 },
            args = { '[Admin]', 'Usage: /tpcoords x y z OU /tpcoords x,y,z OU /tpcoords vector3(x,y,z)' }
        })
        return
    end

    local input = table.concat(args, ' '):gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')
    local x, y, z

    -- vector3(x, y, z)
    local vectorMatch = input:match('vector3%(([^%)]+)%)')
    if vectorMatch then
        local coords = {}
        for coord in string.gmatch(vectorMatch, '([^,]+)') do
            local cleanCoord = coord:gsub('%s+', '')
            if cleanCoord ~= '' then
                local num = tonumber(cleanCoord)
                if num then table.insert(coords, num) end
            end
        end
        if #coords == 3 then
            x, y, z = coords[1], coords[2], coords[3]
        end
    end

    -- x,y,z
    if not x and input:find(',') then
        local coords = {}
        for coord in string.gmatch(input, '([^,]+)') do
            local cleanCoord = coord:gsub('%s+', '')
            if cleanCoord ~= '' then
                local num = tonumber(cleanCoord)
                if num then table.insert(coords, num) end
            end
        end
        if #coords == 3 then
            x, y, z = coords[1], coords[2], coords[3]
        end
    end

    -- x y z
    if not x then
        local coords = {}
        for coord in string.gmatch(input, '([^%s]+)') do
            if coord ~= '' then
                local num = tonumber(coord)
                if num then table.insert(coords, num) end
            end
        end
        if #coords == 3 then
            x, y, z = coords[1], coords[2], coords[3]
        end
    end

    -- Validation
    if not x or not y or not z then
        TriggerServerEvent('r_admin:showNotification', 'Format invalide. Utilisez: x y z, x,y,z ou vector3(x,y,z)',
            'error')
        return
    end

    if math.abs(x) > 10000 or math.abs(y) > 10000 or z < -500 or z > 2000 then
        TriggerServerEvent('r_admin:showNotification', 'Coordonnées hors limites de la carte', 'error')
        return
    end

    -- Téléportation
    local player = PlayerPedId()
    local isInVehicle = IsPedInAnyVehicle(player, false)

    StartPlayerTeleport(PlayerId(), x, y, z, 0.0, isInVehicle, false, true)

    Citizen.CreateThread(function()
        local timeout = 0
        while IsPlayerTeleportActive() and timeout < 100 do
            Citizen.Wait(50)
            timeout = timeout + 1
        end

        if timeout >= 100 then
            TriggerServerEvent('r_admin:showNotification', 'Timeout de téléportation', 'error')
        else
            TriggerServerEvent('r_admin:showNotification',
                string.format('Téléporté: %.1f, %.1f, %.1f', x, y, z), 'success')
        end
    end)
end)

RegisterProtectedCommand('getcoords', function(source, args, rawCommand)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    local x = coords.x
    local y = coords.y
    local z = coords.z
    local h = heading

    local coordsText = x .. ', ' .. y .. ', ' .. z .. ', ' .. h

    SendNUIMessage({
        type = 'clipboard',
        text = coordsText
    })

    TriggerServerEvent('r_admin:showNotification',
        'Coordonnées copiées: ' .. coordsText, 'success')
end)


RegisterNetEvent('r_admin:receivePermissionLevel')
AddEventHandler('r_admin:receivePermissionLevel', function(permissionLevel)
    playerPermissionLevel = permissionLevel or 0
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('r_admin:getPermissionLevel')
end)

-- Recharge le niveau de permission au restart de la resource (mode dev en gros)
AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then
        return
    end

    TriggerServerEvent('r_admin:getPermissionLevel')
end)
