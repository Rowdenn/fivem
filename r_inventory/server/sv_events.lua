local Framework = exports['framework']:GetFramework()

RegisterServerEvent('r_inventory:getPlayerData')
AddEventHandler('r_inventory:getPlayerData', function()
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    local playerData = {
        weight = GetPlayerWeight(identifier),
    }
    
    TriggerClientEvent('r_inventory:updatePlayerData', source, playerData)
end)

RegisterServerEvent('r_inventory:getNearbyPlayers')
AddEventHandler('r_inventory:getNearbyPlayers', function()
    local source = source
    -- TODO : Ajouter la logique pour récupérer les joueurs à proximité
end)

RegisterServerEvent('r_inventory:getItemInfo')
AddEventHandler('r_inventory:getItemInfo', function(itemName)
    local source = source
    local itemData = GetItemData(itemName)
    
    TriggerClientEvent('r_inventory:itemInfo', source, itemData)
end)

-- Event pour récupérer l'inventaire du joueur
RegisterServerEvent('r_inventory:getPlayerInventory')
AddEventHandler('r_inventory:getPlayerInventory', function()
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    local result = Framework.Database:Query('SELECT slot, item, count, metadata FROM inventories WHERE identifier = ?', {identifier})

    -- Récupérer les données des items
    local itemsData = GetAllItemsData()
    
    for _, item in pairs(result) do
        local itemData = itemsData[item.item]
        if itemData then
            item.label = itemData.label
            item.description = itemData.description
            item.weight = itemData.weight
            item.image = itemData.image
            item.usable = itemData.usable
        end

        if item.metadata and type(item.metadata) == 'string' then
            item.metadata = json.decode(item.metadata) or {}
        end
    end
    
    TriggerClientEvent('r_inventory:updateInventory', source, result)
end)

-- Event pour récupérer les items au sol
RegisterServerEvent('r_inventory:getGroundItems')
AddEventHandler('r_inventory:getGroundItems', function()
    local source = source
    local player = GetPlayerPed(source)
    local coords = GetEntityCoords(player)
    
    local result = Framework.Database:Query('SELECT id, item, count, x, y, z FROM ground_items WHERE SQRT(POW(x - ?, 2) + POW(y - ?, 2) + POW(z - ?, 2)) <= 2.0', {
        coords.x,
        coords.y,
        coords.z
    })

    local itemsData = GetAllItemsData()
    local nearbyItems = {}

    for _, groundItem in pairs(result) do
        local itemData = itemsData[groundItem.item] 
        if itemData then
            groundItem.label = itemData.label
            groundItem.image = itemData.image
            groundItem.weight = itemData.weight
        end
        table.insert(nearbyItems, groundItem)
    end
    
    TriggerClientEvent('r_inventory:updateGroundItems', source, nearbyItems) 
end)

RegisterServerEvent('r_inventory:updateGroundItemCoords')
AddEventHandler('r_inventory:updateGroundItemCoords', function(itemId, newCoords)
    local source = source
    
    -- Vérifier que le joueur est proche de l'item
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local distance = #(vector3(newCoords.x, newCoords.y, newCoords.z) - playerCoords)
    
    if distance <= 50.0 then -- Seuil de sécurité
        Framework.Database:Execute('UPDATE ground_items SET x = @x, y = @y, z = @z WHERE id = @id', {
            ['@x'] = newCoords.x,
            ['@y'] = newCoords.y,
            ['@z'] = newCoords.z,
            ['@id'] = itemId
        })
    end
end)

RegisterServerEvent('r_inventory:updateMultipleGroundItemCoords')
AddEventHandler('r_inventory:updateMultipleGroundItemCoords', function(updatedItems)
    local source = source
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    
    for _, itemUpdate in pairs(updatedItems) do
        local itemCoords = vector3(itemUpdate.x, itemUpdate.y, itemUpdate.z)
        local distance = #(itemCoords - playerCoords)
        
        if distance <= 50.0 then
            Framework.Database:Execute('UPDATE ground_items SET x = @x, y = @y, z = @z WHERE id = @id', {
                ['@x'] = itemUpdate.x,
                ['@y'] = itemUpdate.y,
                ['@z'] = itemUpdate.z,
                ['@id'] = itemUpdate.id
            })
        end
    end
end)

RegisterServerEvent('r_inventory:getAllGroundItems')
AddEventHandler('r_inventory:getAllGroundItems', function()
    local source = source
    local player = GetPlayerPed(source)
    local coords = GetEntityCoords(player)
    
    -- Requête pour items dans un rayon de 10 mètres pour l'affichage 3D
    local result = Framework.Database:Query('SELECT id, item, count, x, y, z FROM ground_items WHERE SQRT(POW(x - ?, 2) + POW(y - ?, 2) + POW(z - ?, 2)) <= 10.0', {
        coords.x,
        coords.y,
        coords.z
    })

    local itemsData = GetAllItemsData()
    local allItems = {}
    
    for _, groundItem in pairs(result) do
        local itemData = itemsData[groundItem.item]
        if itemData then
            groundItem.label = itemData.label
            groundItem.image = itemData.image
            groundItem.weight = itemData.weight
        end
        table.insert(allItems, groundItem)
    end
    
    TriggerClientEvent('r_inventory:updateAllGroundItems', source, allItems)
end)

-- Event pour utiliser un item
RegisterServerEvent('r_inventory:useItem')
AddEventHandler('r_inventory:useItem', function(slot, itemName)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    -- Vérifie si le joueur possède l'item
    local hasItem = Framework.Database:Query('SELECT * FROM inventories WHERE identifier = @identifier AND slot = @slot AND item = @item', {
        ['@identifier'] = identifier,
        ['@slot'] = slot,
        ['@item'] = itemName
    })
    
    if hasItem then
        local itemData = GetItemData(itemName)

        if itemData and itemData.usable then
            if itemData.category == 'food' then
                -- TODO : Ajouter le système de métabolisme quand il sera fait
            elseif itemData.type == 'weapon' then
                -- TODO : Ajouter la logique pour équiper une arme
            elseif itemData.type == 'tool' then
                -- TODO : Ajouter un truc jsp si je vais garder cette condition
            end

            if itemData.usable then
                RemoveItemFromInventory(identifier, slot, 1)
            end

            RefreshPlayerInventory(source)
        end
    end
end)

-- Event pour jeter un item
RegisterServerEvent('r_inventory:dropItem')
AddEventHandler('r_inventory:dropItem', function(itemName, count, slot)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    local player = GetPlayerPed(source)
    local coords = GetEntityCoords(player)

    Framework.Database:Execute('INSERT INTO ground_items (item, count, x, y, z) VALUES (@item, @count, @x, @y, @z)', {
        ['@item'] = itemName,
        ['@count'] = count,
        ['@x'] = coords.x,
        ['@y'] = coords.y,
        ['@z']= coords.z
    })

    RemoveItemFromInventory(identifier, slot, count)

    local newItem = Framework.Database:Query('SELECT id, item, count, x, y, z FROM ground_items WHERE x = @x AND y = @y AND z = @z ORDER BY id DESC LIMIT 1', {
        ['@x'] = coords.x,
        ['@y'] = coords.y,
        ['@z']= coords.z
    })

    if newItem[1] then
        local itemsData = GetAllItemsData()
        local itemData = itemsData[newItem[1].item]

        if itemData then
            newItem[1].label = itemData.label
            newItem[1].image = itemData.image
            newItem[1].weight = itemData.weight
        end

        local players = GetPlayers()
        for _, playerId in pairs(players) do
            local player = GetPlayerPed(playerId)
            local playerCoords = GetEntityCoords(player)
            local distance = #(coords - playerCoords)

            if distance <= 2.0 then
                TriggerClientEvent('r_inventory:addGroundItem', playerId, newItem[1])
            end
        end
    end
    
    RefreshPlayerInventory(source)
end)

-- Event pour récupérer un item au sol
RegisterServerEvent('r_inventory:pickupItem')
AddEventHandler('r_inventory:pickupItem', function(groundItemId, toSlot)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    -- Vérifier que l'item existe au sol
    local groundItem = Framework.Database:Query('SELECT * FROM ground_items WHERE id = @id', {
        ['@id'] = groundItemId
    })
    
    if groundItem[1] then
        -- Vérifier que le slot de destination est libre
        local existingItem = Framework.Database:Query('SELECT * FROM inventories WHERE identifier = @identifier AND slot = @slot', {
            ['@identifier'] = identifier,
            ['@slot'] = toSlot
        })
        
        if not existingItem[1] then
            -- Ajouter l'item à l'inventaire au slot spécifié
            AddItemToInventory(identifier, groundItem[1].item, groundItem[1].count, toSlot, json.encode({}))
            
            -- Supprimer l'item du sol
            Framework.Database:Execute('DELETE FROM ground_items WHERE id = @id', {
                ['@id'] = groundItemId
            })
            
            -- Synchronise pour tous les joueurs proches
            TriggerClientEvent('r_inventory:removeGroundItem', -1, groundItemId)
            
            RefreshPlayerInventory(source)
        end
    end
end)

-- Event pour donner un item
RegisterServerEvent('r_inventory:giveItem')
AddEventHandler('r_inventory:giveItem', function(slot, itemName, count)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    -- TODO : Ajouter la logique pour donner un item
    RefreshPlayerInventory(source)
end)

-- Event pour utiliser un quick slot
RegisterServerEvent('r_inventory:useQuickSlot')
AddEventHandler('r_inventory:useQuickSlot', function(quickSlot)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    -- Récupérer l'item dans le quick slot (slot 1-5)
    local result = Framework.Database:Query('SELECT * FROM inventories WHERE identifier = @identifier AND slot = @slot', {
        ['@identifier'] = identifier,
        ['@slot'] = quickSlot
    })
    
    if result[1] then
        -- Utiliser l'item
        TriggerEvent('inventory:useItem', quickSlot, result[1].item)
    end
end)

RegisterServerEvent('r_inventory:moveItem')
AddEventHandler('r_inventory:moveItem', function(fromSlot, fromType, toSlot, toType)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if fromType == 'player' and toType == 'player' then
        -- Déplacer dans l'inventaire du joueur
        local item1 = Framework.Database:Query('SELECT * FROM inventories WHERE identifier = @identifier AND slot = @slot', {
            ['@identifier'] = identifier,
            ['@slot'] = fromSlot
        })
        
        local item2 = Framework.Database:Query('SELECT * FROM inventories WHERE identifier = @identifier AND slot = @slot', {
            ['@identifier'] = identifier,
            ['@slot'] = toSlot
        })
        
        if item1[1] then
            -- Mettre à jour le slot de destination
            Framework.Database:Execute('UPDATE inventories SET slot = @slot WHERE identifier = @identifier AND slot = @fromSlot', {
                ['@slot'] = toSlot,
                ['@identifier'] = identifier,
                ['@fromSlot'] = fromSlot
            })
            
            -- Si il y a un item dans le slot de destination, l'échanger
            if item2[1] then
                Framework.Database:Execute('UPDATE inventories SET slot = @slot WHERE identifier = @identifier AND slot = @toSlot AND id != @excludeId', {
                    ['@slot'] = fromSlot,
                    ['@identifier'] = identifier,
                    ['@toSlot'] = toSlot,
                    ['@excludeId'] = item1[1].id
                })
            end
            
            RefreshPlayerInventory(source)
        end
    end
end)

-- TODO A FIXE
RegisterServerEvent('r_inventory:stackGroundToPlayer')
AddEventHandler('r_inventory:stackGroundToPlayer', function(groundItemId, toSlot, count)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    -- Vérifier que l'item existe au sol
    local groundItem = Framework.Database:Query('SELECT * FROM ground_items WHERE id = @id', {
        ['@id'] = groundItemId
    })
    
    if groundItem[1] then
        -- Vérifier que le slot de destination contient le même item
        local existingItem = Framework.Database:Query('SELECT * FROM inventories WHERE identifier = @identifier AND slot = @slot AND item = @item', {
            ['@identifier'] = identifier,
            ['@slot'] = toSlot,
            ['@item'] = groundItem[1].item
        })
        
        if existingItem[1] then
            -- Stacker les items
            local newCount = existingItem[1].count + groundItem[1].count
            
            Framework.Database:Execute('UPDATE inventories SET count = @count WHERE identifier = @identifier AND slot = @slot', {
                ['@count'] = newCount,
                ['@identifier'] = identifier,
                ['@slot'] = toSlot
            })
            
            -- Supprimer l'item du sol
            Framework.Database:Execute('DELETE FROM ground_items WHERE id = @id', {
                ['@id'] = groundItemId
            })
            
            -- Notifier tous les joueurs proches
            TriggerClientEvent('r_inventory:removeGroundItem', -1, groundItemId)
            
            RefreshPlayerInventory(source)
        end
    end
end)