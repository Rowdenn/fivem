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

                TriggerServerEvent('r_admin:showNotification',
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
                TriggerServerEvent('r_admin:showNotification', money .. '$ (' .. typeLabel .. ') donné à ' .. targetName,
                    'success')
            end
        end
    end)
end
