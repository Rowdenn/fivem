-- Fonction pour ouvrir l'inventaire
function OpenInventory()
    if InventoryOpen then return end
    
    InventoryOpen = true

    UpdateGroundItemsCoordinates()
    
    SetNuiFocus(true, true)
    
    SetTimecycleModifier("hud_def_blur")
    SetTimecycleModifierStrength(0.5)
    
    local playerPed = PlayerPedId()
    SetEntityAlpha(playerPed, 100, false)
    
    CreatePedScreen()

    -- Récupérer les données nécessaires
    RefreshInventory()
    TriggerServerEvent('r_inventory:getGroundItems') -- Items proches pour l'inventaire
    TriggerServerEvent('r_inventory:getNearbyPlayers')
    
    -- Envoyer message d'ouverture
    SendNUIMessage({
        type = 'openInventory',
        playerInventory = {},
        groundItems = GroundItemsForInventory, -- Utiliser les items proches
        playerData = {
            weight = 0
        }
    })
end

-- Fonction pour fermer l'inventaire
function CloseInventory()
    if not InventoryOpen then return end
    
    InventoryOpen = false

    CleanupPedScreen()
    
    SetNuiFocus(false, false)
    
    ClearTimecycleModifier()
    
    local playerPed = PlayerPedId()
    SetEntityAlpha(playerPed, 255, false)
    
    SendNUIMessage({
        type = 'closeInventory'
    })
end

function RefreshInventory()
    TriggerServerEvent('r_inventory:getPlayerInventory')
    TriggerServerEvent('r_inventory:getPlayerData')
end

function UpdateGroundItemsCoordinates()
    local updatedItems = {}
    
    for itemId, object in pairs(GroundObjects) do
        if DoesEntityExist(object) then
            local currentCoords = GetEntityCoords(object)
            local itemData = nil
            
            -- Trouver l'item correspondant
            for _, item in pairs(GroundItemsData) do
                if item.id == itemId then
                    itemData = item
                    break
                end
            end
            
            if itemData then
                local originalCoords = vector3(itemData.x, itemData.y, itemData.z)
                local distance = #(currentCoords - originalCoords)
                
                if distance > 0.5 then
                    table.insert(updatedItems, {
                        id = itemId,
                        x = currentCoords.x,
                        y = currentCoords.y,
                        z = currentCoords.z
                    })
                    
                    -- Mettre à jour localement
                    itemData.x = currentCoords.x
                    itemData.y = currentCoords.y
                    itemData.z = currentCoords.z
                end
            end
        end
    end
    
    -- Envoyer toutes les mises à jour en une fois
    if #updatedItems > 0 then
        TriggerServerEvent('r_inventory:updateMultipleGroundItemCoords', updatedItems)
    end
end

function SpawnGroundItem(itemData)
    if GroundObjects[itemData.id] then
        return
    end

    local hash = GetHashKey('prop_cs_cardbox_01')
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Citizen.Wait(10)
    end

    if HasModelLoaded(hash) then
        local object = CreateObject(hash, itemData.x, itemData.y, itemData.z, false, true, true)
        SetEntityAsMissionEntity(object, true, true)
        SetEntityVelocity(object, 0.0, 0.0, 0.1)
        
        local randomRotation = math.random(0, 360)
        SetEntityRotation(object, 0.0, 0.0, randomRotation, 2, true)

        GroundObjects[itemData.id] = object
    end
end

function RemoveGroundItem(itemId)
    if GroundObjects[itemId] then
        DeleteObject(GroundObjects[itemId])
        GroundObjects[itemId] = nil
    end
end

function CreatePedScreen()
    CreateThread(function()
        -- Nettoyer l'ancien ped s'il existe
        if DoesEntityExist(PlayerPedPreview) then
            DeleteEntity(PlayerPedPreview)
            PlayerPedPreview = nil
        end

        SetFrontendActive(true)
        ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_EMPTY"), true, -1)
        SetMouseCursorVisible(false)
        FrontendActive = true

        Citizen.Wait(100)

        PlayerPedPreview = ClonePed(PlayerPedId(), false, true, false)
        
        if DoesEntityExist(PlayerPedPreview) then
            local x, y, z = table.unpack(GetEntityCoords(PlayerPedPreview))
            
            SetEntityCoords(PlayerPedPreview, x, y, z - 100, false, false, false, false)
            FreezeEntityPosition(PlayerPedPreview, true)
            SetEntityVisible(PlayerPedPreview, false, false)
            NetworkSetEntityInvisibleToNetwork(PlayerPedPreview, false)

            Citizen.Wait(200)

            SetPedAsNoLongerNeeded(PlayerPedPreview)
            GivePedToPauseMenu(PlayerPedPreview, 1)
            ReplaceHudColourWithRgba(117, 0, 0, 0, 0)
            SetPauseMenuPedLighting(true)
            SetPauseMenuPedSleepState(true)
        end
    end)
end

function CleanupPedScreen()
    if DoesEntityExist(PlayerPedPreview) then
        DeleteEntity(PlayerPedPreview)
        PlayerPedPreview = nil
    end
    
    if FrontendActive then
        SetMouseCursorVisible(true)
        SetFrontendActive(false)
        RestartFrontendMenu(GetHashKey("FE_MENU_VERSION_EMPTY_NO_BACKGROUND"), -1)
        FrontendActive = false
    end
end

function UpdateCharacterDisplay()
    if DoesEntityExist(PlayerPedPreview) then
        local heading = GetEntityHeading(PlayerPedPreview)
        
        -- Supprimer l'ancien ped
        DeleteEntity(PlayerPedPreview)
        
        -- Créer le nouveau ped
        PlayerPedPreview = ClonePed(PlayerPedId(), heading, true, false)
        
        if DoesEntityExist(PlayerPedPreview) then
            local x, y, z = table.unpack(GetEntityCoords(PlayerPedPreview))
            
            SetEntityCoords(PlayerPedPreview, x, y, z)
            FreezeEntityPosition(PlayerPedPreview, true)
            SetEntityVisible(PlayerPedPreview, false, false)
            NetworkSetEntityInvisibleToNetwork(PlayerPedPreview, false)
            
            Citizen.Wait(200)
            
            SetPedAsNoLongerNeeded(PlayerPedPreview)
            GivePedToPauseMenu(PlayerPedPreview, 2)
            SetPauseMenuPedLighting(true)
            SetPauseMenuPedSleepState(true)
        end
    end
end