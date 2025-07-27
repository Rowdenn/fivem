function GetReasonForAction(actionType, targetId, targetName)
    Citizen.CreateThread(function()
        AddTextEntry('FMMC_MPM_NA', 'Raison pour ' .. actionType .. ' ' .. targetName .. ' :')
        DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 100)

        while UpdateOnscreenKeyboard() == 0 do
            DisableAllControlActions(0)
            Wait(0)
        end

        if GetOnscreenKeyboardResult() then
            local reason = GetOnscreenKeyboardResult()
            if reason and reason ~= '' then
                if actionType == 'kick' then
                    TriggerServerEvent('r_admin:kickPlayer', targetId, reason)
                elseif actionType == 'ban' then
                    TriggerServerEvent('r_admin:banPlayer', targetId, reason)
                end

                TriggerServerEvent('r_admin:client:showNotification',
                    actionType:upper() .. ' de ' .. targetName .. ' effectué', 'success')
            end
        end
    end)
end

function GetMoneyAmount(targetId, targetName, moneyType)
    local typeLabel = moneyType == 'cash' and 'argent cash' or 'argent en banque'

    Citizen.CreateThread(function()
        AddTextEntry('FMMC_MPM_NA', 'Montant de ' .. typeLabel .. ' à donner à ' .. targetName .. ' :')
        DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "1000", "", "", "", 15)

        while UpdateOnscreenKeyboard() == 0 do
            DisableAllControlActions(0)
            Wait(0)
        end

        if GetOnscreenKeyboardResult() then
            local amountStr = GetOnscreenKeyboardResult()
            local money = tonumber(amountStr)

            if money and money > 0 then
                print("Argent donné: ", money)
                TriggerServerEvent('r_admin:giveMoney', targetId, moneyType, money)
                TriggerServerEvent('r_admin:client:showNotification',
                    money .. '$ (' .. typeLabel .. ') donné à ' .. targetName,
                    'success')
            end
        end
    end)
end

RegisterNetEvent('r_admin:teleportPlayer')
AddEventHandler('r_admin:teleportPlayer', function(coords)
    local player = PlayerPedId()
    local isInVehicle = IsPedInAnyVehicle(player, false)

    StartPlayerTeleport(PlayerId(), coords.x, coords.y, coords.z, 0.0, isInVehicle, true)

    Citizen.CreateThread(function()
        while IsPlayerTeleportActive() do
            Citizen.Wait(0)
        end

        local heightAboveGround = GetEntityHeightAboveGround(player)
        if heightAboveGround > 5.0 then
            local playerCoords = GetEntityCoords(player)
            local found, groundZ = GetGroundZFor_3dCoord(playerCoords.x, playerCoords.y, playerCoords.z, false)
            if found then
                if isInVehicle then
                    local vehicle = GetVehiclePedIsIn(player, false)
                    SetEntityCoords(vehicle, playerCoords.x, playerCoords.y, groundZ + 1.0)
                else
                    SetEntityCoords(player, playerCoords.x, playerCoords.y, groundZ + 1.0)
                end
            end
        end
    end)
end)

RegisterNetEvent('r_admin:receivePlayersList')
AddEventHandler('r_admin:receivePlayersList', function(players)
    local playersMenu = MenuV:CreateMenu("Joueurs connectés", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    table.sort(players, function(a, b) return a.name < b.name end)

    for _, player in pairs(players) do
        playersMenu:AddButton({
            icon = '👤',
            label = player.name .. '[' .. player.id .. ']',
            description = 'Actions sur ',
            player.name,
            select = function()
                OpenPlayerActionsMenu(player.id, player.name)
            end
        })
    end

    playersMenu:Open()
end)
