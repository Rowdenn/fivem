local inventoryOpen = false
local nearbyPlayers = {}
local groundObjects = {}
local groundItemsData = {}
local groundItemsForInventory = {}
local PlayerPedPreview = nil
local frontendActive = false

-- Fonction pour ouvrir l'inventaire
function OpenInventory()
    if inventoryOpen then return end
    
    inventoryOpen = true

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
        groundItems = groundItemsForInventory, -- Utiliser les items proches
        playerData = {
            weight = 0
        }
    })
end

-- Fonction pour fermer l'inventaire
function CloseInventory()
    if not inventoryOpen then return end
    
    inventoryOpen = false

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
    
    for itemId, object in pairs(groundObjects) do
        if DoesEntityExist(object) then
            local currentCoords = GetEntityCoords(object)
            local itemData = nil
            
            -- Trouver l'item correspondant
            for _, item in pairs(groundItemsData) do
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
    if groundObjects[itemData.id] then
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
        
        -- Faire rebondir l'objet légèrement
        SetEntityVelocity(object, 0.0, 0.0, 0.1)
        
        -- Optionnel : Ajouter une légère rotation aléatoire
        local randomRotation = math.random(0, 360)
        SetEntityRotation(object, 0.0, 0.0, randomRotation, 2, true)

        groundObjects[itemData.id] = object
    end
end

function RemoveGroundItem(itemId)
    if groundObjects[itemId] then
        DeleteObject(groundObjects[itemId])
        groundObjects[itemId] = nil
    end
end

function CreatePedScreen()
    CreateThread(function()
        -- Nettoyer l'ancien ped s'il existe
        if DoesEntityExist(PlayerPedPreview) then
            DeleteEntity(PlayerPedPreview)
            PlayerPedPreview = nil
        end
        
        local heading = GetEntityHeading(PlayerPedId())

        SetFrontendActive(true)
        ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_EMPTY_NO_BACKGROUND"), true, -1)
        frontendActive = true

        Citizen.Wait(100)

        N_0x98215325a695e78a(false)

        PlayerPedPreview = ClonePed(PlayerPedId(), heading, true, false)
        
        if DoesEntityExist(PlayerPedPreview) then
            local x, y, z = table.unpack(GetEntityCoords(PlayerPedPreview))
            
            SetEntityCoords(PlayerPedPreview, x, y, z - 10)
            FreezeEntityPosition(PlayerPedPreview, true)
            SetEntityVisible(PlayerPedPreview, false, false)
            NetworkSetEntityInvisibleToNetwork(PlayerPedPreview, false)

            Citizen.Wait(200)

            SetPedAsNoLongerNeeded(PlayerPedPreview)
            GivePedToPauseMenu(PlayerPedPreview, 2)
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
    
    if frontendActive then
        SetFrontendActive(false)
        RestartFrontendMenu(GetHashKey("FE_MENU_VERSION_EMPTY_NO_BACKGROUND"), -1)
        frontendActive = false
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
            
            SetEntityCoords(PlayerPedPreview, x, y, z - 10)
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

-- Détecte les joueurs proches
Citizen.CreateThread(function()
    while true do
        if inventoryOpen then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local players = {}
            
            for _, player in pairs(GetActivePlayers()) do
                if player ~= PlayerId() then
                    local targetPed = GetPlayerPed(player)
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)
                    
                    if distance <= 3.0 then
                        table.insert(players, {
                            id = GetPlayerServerId(player),
                            name = GetPlayerName(player),
                            distance = distance
                        })
                    end
                end
            end
            
            nearbyPlayers = players
            
            SendNUIMessage({
                type = 'updateNearbyPlayers',
                players = nearbyPlayers
            })
        end
        
        Citizen.Wait(inventoryOpen and 1000 or 5000)
    end
end)

-- Gestion des touches
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- Touche TAB pour ouvrir/fermer l'inventaire
        if IsControlJustPressed(0, 37) then -- TAB
            if inventoryOpen then
                CloseInventory()
            else
                OpenInventory()
            end
        end
        
        -- Échap pour fermer l'inventaire
        if IsControlJustPressed(0, 177) and inventoryOpen then -- ESC
            CloseInventory()
        end
        
        -- Touches de raccourci (1-5) pour les quick slots
        if not inventoryOpen then
            for i = 1, 5 do
                local control = i + 1 -- Les contrôles 2-6 correspondent aux touches 1-5
                if IsControlJustPressed(0, control) then
                    TriggerServerEvent('r_inventory:useQuickSlot', i)
                end
            end
        end
    end
end)

-- Thread pour afficher le texte 3D de l'item au sol
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local player = PlayerPedId()
        local playerCoords = GetEntityCoords(player)

        for itemId, object in pairs(groundObjects) do
            if DoesEntityExist(object) then
                local objectCoords = GetEntityCoords(object)
                local distance = #(playerCoords - objectCoords)

                if distance <= 10.0 then -- Distance d'affichage du texte
                    local itemData = nil
                    for _, item in pairs(groundItemsData) do
                        if item.id == itemId then
                            itemData = item
                            break
                        end
                    end

                    if itemData then
                        -- Calcul la position du texte au-dessus de l'objet
                        local textCoords = GetOffsetFromEntityInWorldCoords(object, 0.0, 0.0, 0.5)
                        local onScreen, x, y = World3dToScreen2d(textCoords.x, textCoords.y, textCoords.z)

                        if onScreen then
                            local textScale = math.max(0.25, 0.5 - (distance * 0.03))
                            
                            SetTextScale(textScale, textScale)
                            SetTextFont(4)
                            SetTextCentre(true)
                            SetTextColour(255, 255, 255, 255)
                            SetTextOutline()

                            local displayText = itemData.label or itemData.item
                            if itemData.count > 1 then
                                displayText = displayText .. " x" .. itemData.count
                            end

                            SetTextEntry("STRING")
                            AddTextComponentString(displayText)
                            DrawText(x, y)
                        end
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        for itemId, object in pairs(groundObjects) do
            if DoesEntityExist(object) then
                local currentCoords = GetEntityCoords(object)
                local itemData = nil
                
                -- Trouver l'item correspondant dans groundItemsData
                for _, item in pairs(groundItemsData) do
                    if item.id == itemId then
                        itemData = item
                        break
                    end
                end
                
                if itemData then
                    local originalCoords = vector3(itemData.x, itemData.y, itemData.z)
                    local distance = #(currentCoords - originalCoords)
                    
                    -- Si l'objet s'est déplacé de plus de 1 mètre
                    if distance > 2.0 then
                        -- Mettre à jour les coordonnées localement
                        itemData.x = currentCoords.x
                        itemData.y = currentCoords.y
                        itemData.z = currentCoords.z
                        
                        -- Envoyer la mise à jour au serveur
                        TriggerServerEvent('r_inventory:updateGroundItemCoords', itemId, currentCoords)
                    end
                end
            end
        end
        
        Citizen.Wait(5000) -- Vérifier toutes les 5 secondes
    end
end)

-- Thread pour charger automatiquement les items au sol
Citizen.CreateThread(function()
    local lastUpdate = 0
    local lastCoords = vector3(0, 0, 0)

    Citizen.Wait(2000)
    TriggerServerEvent('r_inventory:getAllGroundItems')

    while true do
        local currentTime = GetGameTimer()
        local player = PlayerPedId()
        local currentCoords = GetEntityCoords(player)

        local distance = #(currentCoords - lastCoords)
        local timeSinceUpdate = currentTime - lastUpdate
        
        -- Mise à jour des items visibles (3D)
        if distance > 25.0 or timeSinceUpdate > 15000 then
            TriggerServerEvent('r_inventory:getAllGroundItems')
            lastCoords = currentCoords
            lastUpdate = currentTime
        end
        
        Citizen.Wait(2000)
    end
end)

Citizen.CreateThread(function()
    while true do
        if inventoryOpen then
            -- Mise à jour fréquente des items très proches pour l'inventaire
            TriggerServerEvent('r_inventory:getGroundItems')
            Citizen.Wait(1000)
        else
            Citizen.Wait(5000)
        end
    end
end)

-- Callbacks NUI
RegisterNUICallback('closeInventory', function(data, cb)
    CloseInventory()
    cb('ok')
end)

RegisterNUICallback('useItem', function(data, cb)
    TriggerServerEvent('r_inventory:useItem', data.slot, data.item)
    cb('ok')
end)

RegisterNUICallback('dropItem', function(data, cb)
    TriggerServerEvent('r_inventory:dropItem', data.item, data.count, data.slot)
    cb('ok')
end)

RegisterNUICallback('giveItem', function(data, cb)
    if data.targetId then
        TriggerServerEvent('r_inventory:giveItem', data.slot, data.item, data.count or 1, data.targetId)
    end
    cb('ok')
end)

RegisterNUICallback('moveItem', function(data, cb)
    TriggerServerEvent('r_inventory:moveItem', data.fromSlot, data.fromType, data.toSlot, data.toType)
    cb('ok')
end)

RegisterNUICallback('pickupItem', function(data, cb)
    print('message pickupItem triggered')
    TriggerServerEvent('r_inventory:pickupItem', data.groundItemId, data.toSlot)
    cb('ok')
end)

RegisterNUICallback('sortInventory', function(data, cb)
    TriggerServerEvent('r_inventory:sortInventory')
    cb('ok')
end)

RegisterNUICallback('getItemInfo', function(data, cb)
    TriggerServerEvent('r_inventory:getItemInfo', data.item)
    cb('ok')
end)

RegisterNUICallback('stackGroundToPlayer', function(data, cb)
    TriggerServerEvent('r_inventory:stackGroundToPlayer', data.groundItemId, data.toSlot, data.count)
    cb('ok')
end)

RegisterNUICallback('updateCharacterDisplay', function(data, cb)
    UpdateCharacterDisplay()
    cb('ok')
end)

-- Events serveur
RegisterNetEvent('r_inventory:updateInventory')
AddEventHandler('r_inventory:updateInventory', function(inventory)
    SendNUIMessage({
        type = 'updateInventory',
        inventory = inventory
    })
end)

RegisterNetEvent('r_inventory:updateGroundItems')
AddEventHandler('r_inventory:updateGroundItems', function(groundItems)
    groundItemsData = groundItems

    for _, item in pairs(groundItems) do
        if not groundObjects[item.id] then
            SpawnGroundItem(item)
        end
    end

    SendNUIMessage({
        type = 'updateGroundItems',
        groundItems = groundItems
    })
end)

RegisterNetEvent('r_inventory:removeGroundItem')
AddEventHandler('r_inventory:removeGroundItem', function(itemId)
    RemoveGroundItem(itemId)

    for i, item in pairs(groundItemsData) do
        if item.id == itemId then
            table.remove(groundItemsData, i)
            break
        end
    end

    if inventoryOpen then
        SendNUIMessage({
            type = 'updateGroundItems',
            groundItems = groundItemsData
        })
    end
end)

RegisterNetEvent('r_inventory:updatePlayerData')
AddEventHandler('r_inventory:updatePlayerData', function(data)
    playerData = data
    SendNUIMessage({
        type = 'updatePlayerData',
        playerData = data
    })
end)

RegisterNetEvent('r_inventory:itemInfo')
AddEventHandler('r_inventory:itemInfo', function(itemData)
    SendNUIMessage({
        type = 'itemInfo',
        itemData = itemData
    })
end)

RegisterNetEvent('r_inventory:addGroundItem')
AddEventHandler('r_inventory:addGroundItem', function(newItem)
    table.insert(groundItemsData, newItem)
    SpawnGroundItem(newItem)

    SendNUIMessage({
        type = 'addGroundItem',
        groundItem = newItem
    })
end)

RegisterNetEvent('r_inventory:updateAllGroundItems')
AddEventHandler('r_inventory:updateAllGroundItems', function(allGroundItems)
    -- Supprimer les objets qui ne sont plus dans la liste
    local newItemIds = {}
    for _, item in pairs(allGroundItems) do
        newItemIds[item.id] = true
    end

    for itemId, object in pairs(groundObjects) do
        if not newItemIds[itemId] then
            DeleteObject(object)
            groundObjects[itemId] = nil
        end
    end

    -- Mettre à jour les données pour l'affichage 3D
    groundItemsData = allGroundItems

    -- Spawn les nouveaux objets
    for _, item in pairs(allGroundItems) do
        if not groundObjects[item.id] then
            SpawnGroundItem(item)
        end
    end
end)

RegisterNetEvent('r_inventory:getPlayerInventory')
AddEventHandler('r_inventory:getPlayerInventory', function(playerData)
    SendNUIMessage({
        type = 'updatePlayerModel',
        groundItem = playerData
    })
end)