local playerPermissionLevel = 0

function HasPermissionClient(requiredLevel)
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

        if not HasPermissionClient(requiredLevel) then
            TriggerServerEvent('r_admin:client:showNotification',
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
    local teleportCoords = {}

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
            teleportCoords.x, teleportCoords.y, teleportCoords.z = coords[1], coords[2], coords[3]
        end
    end

    -- x,y,z
    if not teleportCoords.x and input:find(',') then
        local coords = {}
        for coord in string.gmatch(input, '([^,]+)') do
            local cleanCoord = coord:gsub('%s+', '')
            if cleanCoord ~= '' then
                local num = tonumber(cleanCoord)
                if num then table.insert(coords, num) end
            end
        end
        if #coords == 3 then
            teleportCoords.x, teleportCoords.y, teleportCoords.z = coords[1], coords[2], coords[3]
        end
    end

    -- x y z
    if not teleportCoords.x then
        local coords = {}
        for coord in string.gmatch(input, '([^%s]+)') do
            if coord ~= '' then
                local num = tonumber(coord)
                if num then table.insert(coords, num) end
            end
        end
        if #coords == 3 then
            teleportCoords.x, teleportCoords.y, teleportCoords.z = coords[1], coords[2], coords[3]
        end
    end

    -- Validation
    if not teleportCoords.x or not teleportCoords.y or not teleportCoords.z then
        TriggerServerEvent('r_admin:client:showNotification', 'Format invalide. Utilisez: x y z, x,y,z ou vector3(x,y,z)',
            'error')
        return
    end

    if math.abs(teleportCoords.x) > 10000 or math.abs(teleportCoords.y) > 10000 or teleportCoords.z < -500 or teleportCoords.z > 2000 then
        TriggerServerEvent('r_admin:client:showNotification', 'Coordonnées hors limites de la carte', 'error')
        return
    end

    TriggerEvent('r_admin:teleportPlayer', teleportCoords)
end)

RegisterProtectedCommand('getcoords', function(source, args, rawCommand)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    local x = string.format("%.3f", coords.x)
    local y = string.format("%.3f", coords.y)
    local z = string.format("%.3f", coords.z)
    local h = string.format("%.3f", heading)

    local coordsText = 'vec3(' .. x .. ', ' .. y .. ', ' .. z .. ')'

    SendNUIMessage({
        action = 'loadUI',
        module = 'admin',
        data = {
            text = coordsText
        }
    })

    TriggerServerEvent('r_admin:client:showNotification',
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
