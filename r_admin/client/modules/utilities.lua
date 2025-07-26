function GetCoordinatesForTeleport()
    Citizen.CreateThread(function()
        -- Coordonnée X
        AddTextEntry('FMMC_MPM_NA', 'Coordonnée X :')
        DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "0.0", "", "", "", 10)

        while UpdateOnscreenKeyboard() == 0 do
            DisableAllControlActions(0)
            Wait(0)
        end

        if not GetOnscreenKeyboardResult() then return end
        local x = tonumber(GetOnscreenKeyboardResult())
        if not x then return end

        -- Coordonnée Y
        AddTextEntry('FMMC_MPM_NA', 'Coordonnée Y :')
        DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "0.0", "", "", "", 10)

        while UpdateOnscreenKeyboard() == 0 do
            DisableAllControlActions(0)
            Wait(0)
        end

        if not GetOnscreenKeyboardResult() then return end
        local y = tonumber(GetOnscreenKeyboardResult())
        if not y then return end

        -- Coordonnée Z
        AddTextEntry('FMMC_MPM_NA', 'Coordonnée Z :')
        DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "0.0", "", "", "", 10)

        while UpdateOnscreenKeyboard() == 0 do
            DisableAllControlActions(0)
            Wait(0)
        end

        if not GetOnscreenKeyboardResult() then return end
        local z = tonumber(GetOnscreenKeyboardResult())
        if not z then return end

        SetEntityCoords(PlayerPedId(), x, y, z)
        TriggerServerEvent('r_admin:showNotification', 'Téléporté aux coordonnées: ' .. x .. ', ' .. y .. ', ' .. z,
            'success')
    end)
end

function GetWeaponForSelf()
    Citizen.CreateThread(function()
        AddTextEntry('FMMC_MPM_NA', 'Arme à recevoir (ex: WEAPON_PISTOL):')
        DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "WEAPON_", "", "", "", 50)

        while UpdateOnscreenKeyboard() == 0 do
            DisableAllControlActions(0)
            Wait(0)
        end

        if GetOnscreenKeyboardResult() then
            local weaponName = GetOnscreenKeyboardResult():upper()
            if weaponName and weaponName ~= '' and weaponName ~= 'WEAPON_' then
                -- Demander les munitions
                AddTextEntry('FMMC_MPM_NA', 'Munitions pour ' .. weaponName .. ' :')
                DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "250", "", "", "", 10)

                while UpdateOnscreenKeyboard() == 0 do
                    DisableAllControlActions(0)
                    Wait(0)
                end

                if GetOnscreenKeyboardResult() then
                    local ammo = tonumber(GetOnscreenKeyboardResult()) or 250
                    local playerPed = PlayerPedId()
                    local weaponHash = GetHashKey(weaponName)

                    GiveWeaponToPed(playerPed, weaponHash, ammo, false, true)

                    TriggerEvent('chat:addMessage', {
                        color = { 0, 255, 0 },
                        args = { '[Admin]', 'Arme ' .. weaponName .. ' reçue avec ' .. ammo .. ' munitions !' }
                    })
                end
            end
        end
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
