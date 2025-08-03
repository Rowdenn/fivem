RegisterNetEvent('r_inventory:updateGroundItems')
AddEventHandler('r_inventory:updateGroundItems', function(groundItems)
    GroundItemsData = groundItems

    for _, item in pairs(groundItems) do
        if not GroundObjects[item.id] then
            SpawnGroundItem(item)
        end
    end

    UpdateGroundItemsUI(groundItems)
end)

RegisterNetEvent('r_inventory:removeGroundItem')
AddEventHandler('r_inventory:removeGroundItem', function(itemId)
    RemoveGroundItem(itemId)

    for i, item in pairs(GroundItemsData) do
        if item.id == itemId then
            table.remove(GroundItemsData, i)
            break
        end
    end

    if InventoryOpen then
        UpdateGroundItemsUI(GroundItemsData)
    end
end)

RegisterNetEvent('r_inventory:updatePlayerData')
AddEventHandler('r_inventory:updatePlayerData', function(data)
    playerData = data
    UpdatePlayerDataUI(data)
end)

RegisterNetEvent('r_inventory:itemInfo')
AddEventHandler('r_inventory:itemInfo', function(itemData)
    SendNUIMessage({
        action = 'updateUI',
        module = 'inventory',
        data = {
            type = 'itemInfo',
            itemData = itemData
        }
    })
end)

RegisterNetEvent('r_inventory:addGroundItem')
AddEventHandler('r_inventory:addGroundItem', function(newItem)
    table.insert(GroundItemsData, newItem)
    SpawnGroundItem(newItem)

    SendNUIMessage({
        action = 'updateUI',
        module = 'inventory',
        data = {
            type = 'addGroundItem',
            groundItem = newItem
        }
    })
end)

RegisterNetEvent('r_inventory:updateAllGroundItems')
AddEventHandler('r_inventory:updateAllGroundItems', function(allGroundItems)
    -- Supprimer les objets qui ne sont plus dans la liste
    local newItemIds = {}
    for _, item in pairs(allGroundItems) do
        newItemIds[item.id] = true
    end

    for itemId, object in pairs(GroundObjects) do
        if not newItemIds[itemId] then
            DeleteObject(object)
            GroundObjects[itemId] = nil
        end
    end

    -- Mettre à jour les données pour l'affichage 3D
    GroundItemsData = allGroundItems

    -- Spawn les nouveaux objets
    for _, item in pairs(allGroundItems) do
        if not GroundObjects[item.id] then
            SpawnGroundItem(item)
        end
    end
end)

RegisterAndHandleNetEvent('r_inventory:updateInventory', function(inventory)
    -- Toujours mettre à jour l'interface avec les nouvelles données, même si déjà chargée
    if InventoryOpen then
        -- Si c'est la première fois et qu'on a des vraies données, afficher avec les données
        if not InventoryLoaded then
            SendNUIMessage({
                action = 'loadUI',
                module = 'inventory',
                data = {
                    type = 'openInventory',
                    playerInventory = inventory,
                    groundItems = GroundItemsForInventory or {},
                    playerData = playerData or { weight = 0 }
                }
            })
            InventoryLoaded = true
        else
            print('DEBUG: Mise à jour avec update')
            -- Sinon, juste mettre à jour les données existantes
            SendNUIMessage({
                action = 'updateUI',
                module = 'inventory',
                data = {
                    type = 'updateInventory',
                    inventory = inventory
                }
            })
        end
    end
end)
