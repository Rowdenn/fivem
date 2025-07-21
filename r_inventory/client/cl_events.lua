RegisterNetEvent('r_inventory:updateInventory')
AddEventHandler('r_inventory:updateInventory', function(inventory)
    SendNUIMessage({
        type = 'updateInventory',
        inventory = inventory
    })
end)

RegisterNetEvent('r_inventory:updateGroundItems')
AddEventHandler('r_inventory:updateGroundItems', function(groundItems)
    GroundItemsData = groundItems

    for _, item in pairs(groundItems) do
        if not GroundObjects[item.id] then
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

    for i, item in pairs(GroundItemsData) do
        if item.id == itemId then
            table.remove(GroundItemsData, i)
            break
        end
    end

    if InventoryOpen then
        SendNUIMessage({
            type = 'updateGroundItems',
            groundItems = GroundItemsData
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
    table.insert(GroundItemsData, newItem)
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

RegisterNetEvent('r_inventory:getPlayerInventory')
AddEventHandler('r_inventory:getPlayerInventory', function(playerData)
    SendNUIMessage({
        type = 'updatePlayerModel',
        groundItem = playerData
    })
end)