-- Détecte les joueurs proches
Citizen.CreateThread(function()
    while true do
        if InventoryOpen then
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
            
            NearbyPlayers = players
            
            SendNUIMessage({
                type = 'updateNearbyPlayers',
                players = NearbyPlayers
            })
        end
        
        Citizen.Wait(InventoryOpen and 1000 or 5000)
    end
end)

-- Gestion des touches
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- Touche TAB pour ouvrir/fermer l'inventaire
        if IsControlJustPressed(0, 37) then -- TAB
            if InventoryOpen then
                CloseInventory()
            else
                OpenInventory()
            end
        end
        
        -- Échap pour fermer l'inventaire
        if IsControlJustPressed(0, 177) and InventoryOpen then -- ESC
            CloseInventory()
        end
        
        -- Touches de raccourci (1-5) pour les quick slots
        if not InventoryOpen then
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

        for itemId, object in pairs(GroundObjects) do
            if DoesEntityExist(object) then
                local objectCoords = GetEntityCoords(object)
                local distance = #(playerCoords - objectCoords)

                if distance <= 10.0 then -- Distance d'affichage du texte
                    local itemData = nil
                    for _, item in pairs(GroundItemsData) do
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
        for itemId, object in pairs(GroundObjects) do
            if DoesEntityExist(object) then
                local currentCoords = GetEntityCoords(object)
                local itemData = nil
                
                -- Trouver l'item correspondant dans GroundItemsData
                for _, item in pairs(GroundItemsData) do
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
        if InventoryOpen then
            -- Mise à jour fréquente des items très proches pour l'inventaire
            TriggerServerEvent('r_inventory:getGroundItems')
            Citizen.Wait(1000)
        else
            Citizen.Wait(5000)
        end
    end
end)