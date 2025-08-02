
function DetermineModelBySex(sex)
    if sex == 0 then
        return "mp_m_freemode_01"
    else
        return "mp_f_freemode_01"
    end
end

function LoadPlayerModel(modelName, freezePlayer)
    local model = GetHashKey(modelName)
    local currentModel = GetEntityModel(PlayerPedId())

    if currentModel == model then
        return true
    end
    
    if not IsModelValid(model) then
        print('ERREUR: Modèle invalide:', modelName)
        return false
    end
    
    RequestModel(model)
    
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Citizen.Wait(50)
        timeout = timeout + 1
    end
    
    if HasModelLoaded(model) then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)

        Citizen.Wait(500)
        
        -- Vérifie que le nouveau ped existe
        local newPed = PlayerPedId()
        local pedTimeout = 0
        while not DoesEntityExist(newPed) and pedTimeout < 50 do
            Citizen.Wait(50)
            newPed = PlayerPedId()
            pedTimeout = pedTimeout + 1
        end
        
        if DoesEntityExist(newPed) then
            SetEntityCoords(newPed, coords.x, coords.y, coords.z - 1, false, false, false, true)
            SetEntityHeading(newPed, heading)

            -- Active la personnalisation des couleurs, barbes etc...
            SetPedHeadBlendData(newPed, 0, 0, 0, 0, 0, 0, 0, 0, 0, false)
            Citizen.Wait(50)

            if freezePlayer then
                FreezeEntityPosition(newPed, true)
                SetEntityInvincible(newPed, true)
            else
                FreezeEntityPosition(newPed, false)
                SetEntityInvincible(newPed, false)
            end

            -- Model chargé
            return true
        else
            -- Ped non trouvé
            return false
        end
    else 
        -- Model non chargé
        return false
    end
end