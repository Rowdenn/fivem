function TeleportToWaypoint()
    local waypoint = GetFirstBlipInfoId(8)

    if not DoesBlipExist(waypoint) then
        TriggerServerEvent('r_admin:showNotification', 'Aucun waypoint trouvé sur la carte', 'error')
        return
    end

    local coords = GetBlipCoords(waypoint)
    local x, y = coords.x, coords.y
    local z = 100.0

    local player = PlayerPedId()
    local isInVehicle = IsPedInAnyVehicle(player, false)

    StartPlayerTeleport(PlayerId(), x, y, z, 0.0, isInVehicle, true)

    Citizen.CreateThread(function()
        while IsPlayerTeleportActive() do
            Citizen.Wait(0)
        end

        local heightAboveGround = GetEntityHeightAboveGround(PlayerPedId())
        if heightAboveGround > 5.0 then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local found, groundZ = GetGroundZFor_3dCoord(playerCoords.x, playerCoords.y, playerCoords.z, false)
            if found then
                if isInVehicle then
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    SetEntityCoords(vehicle, playerCoords.x, playerCoords.y, groundZ + 1.0)
                else
                    SetEntityCoords(PlayerPedId(), playerCoords.x, playerCoords.y, groundZ + 1.0)
                end
            end
        end

        TriggerServerEvent('r_admin:showNotification', 'Téléporté au waypoint', 'success')
    end)
end

function GetMoneyAmountForSelf(moneyType)
    local typeLabel = moneyType == 'cash' and 'argent cash' or 'argent en banque'

    Citizen.CreateThread(function()
        AddTextEntry('FMMC_MPM_NA', 'Montant de ' .. typeLabel .. ' :')
        DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "1000", "", "", "", 15)

        while UpdateOnscreenKeyboard() == 0 do
            DisableAllControlActions(0)
            Wait(0)
        end

        if GetOnscreenKeyboardResult() then
            local money = tonumber(GetOnscreenKeyboardResult())
            if money and money > 0 then
                TriggerServerEvent('admin:giveMoneySelf', moneyType, money)
                TriggerEvent('chat:addMessage', {
                    color = { 0, 255, 0 },
                    args = { '[Admin]', 'Vous avez reçu ' .. money .. '$ (' .. typeLabel .. ') !' }
                })
            end
        end
    end)
end

function GetTimeForServer()
    Citizen.CreateThread(function()
        -- Demander l'heure
        AddTextEntry('FMMC_MPM_NA', 'Heure (0-23) :')
        DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "12", "", "", "", 2)

        while UpdateOnscreenKeyboard() == 0 do
            DisableAllControlActions(0)
            Wait(0)
        end

        if not GetOnscreenKeyboardResult() then return end
        local hour = tonumber(GetOnscreenKeyboardResult())
        if not hour or hour < 0 or hour > 23 then return end

        -- Demander les minutes
        AddTextEntry('FMMC_MPM_NA', 'Minutes (0-59) :')
        DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "0", "", "", "", 2)

        while UpdateOnscreenKeyboard() == 0 do
            DisableAllControlActions(0)
            Wait(0)
        end

        local minute = 0
        if GetOnscreenKeyboardResult() then
            minute = tonumber(GetOnscreenKeyboardResult()) or 0
        end

        if minute >= 0 and minute <= 59 then
            TriggerServerEvent('admin:setTime', hour, minute)
            TriggerEvent('chat:addMessage', {
                color = { 0, 255, 0 },
                args = { '[Admin]', 'Heure définie à: ' .. hour .. 'h' .. string.format('%02d', minute) }
            })
        end
    end)
end
