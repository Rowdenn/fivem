local Framework = exports['framework']:GetFramework()

-- Fonction pour obtenir l'inventaire d'un joueur
function GetPlayerInventory(identifier)
    local inventory = {}
    
    -- Requête SQL pour récupérer l'inventaire
    local result = Framework.Database:Query('SELECT * FROM inventories WHERE identifier = @identifier ORDER BY slot ASC', {
        ['@identifier'] = identifier
    })
    
    for _, item in pairs(result) do
        local inventoryItem = {
            item = item.item,
            count = item.count,
            metadata = json.decode(item.metadata or '{}'),
            slot = item.slot
        }

        table.insert(inventory, inventoryItem)
    end
    
    return inventory
end

-- Fonction pour obtenir les informations d'un item
function GetItemData(itemName)
    local result = Framework.Database:Query('SELECT * FROM items WHERE name = @name', {
        ['@name'] = itemName
    })
    
    if result[1] then
        return result[1]
    end
    
    return nil
end

function GetAllItemsData()
    local result = Framework.Database:Query('SELECT * FROM items', {})
    local itemsData = {}
    for _, item in pairs(result) do
        itemsData[item.name] = item
    end
    return itemsData
end

-- Fonction pour trouver un slot d'inventaire libre
function GetFreeInventorySlot(identifier)
    local result = Framework.Database:Query('SELECT slot FROM inventories WHERE identifier = @identifier ORDER BY slot ASC', {
        ['@identifier'] = identifier
    })
    
    -- Créer un tableau des slots occupés
    local occupiedSlots = {}
    for _, item in pairs(result) do
        occupiedSlots[item.slot] = true
    end
    
    -- Trouver le premier slot libre
    for slot = 1, 120 do
        if not occupiedSlots[slot] then
            return slot
        end
    end

    return nil
end

-- Fonction pour ajouter un item à l'inventaire
function AddItemToInventory(identifier, itemName, count, slot, metadata)
    metadata = metadata or {}

    local freeSlot = GetFreeInventorySlot(identifier)
    if not freeSlot then
        return false, 'Inventaire plein'
    end

    Framework.Database:Execute('INSERT INTO inventories (identifier, item, count, slot, metadata) VALUES (@identifier, @item, @count, @slot, @metadata)', {
        ['@identifier'] = identifier,
        ['@item'] = itemName,
        ['@count'] = count,
        ['@slot'] = slot,
        ['@metadata'] = json.encode(metadata)
    })

    return true, 'Item ajouté'
end

function RemoveItemFromInventory(identifier, slot, count)
    local currentItem = Framework.Database:Query('SELECT * FROM inventories WHERE identifier = @identifier AND slot = @slot', {
        ['@identifier'] = identifier,
        ['@slot'] = slot
    })

    if not currentItem[1] or not currentItem[1].count then
        return false, 'Item introuvable'
    end
    
    local newCount = currentItem[1].count - count

    if newCount <= 0 then
        Framework.Database:Execute('DELETE FROM inventories WHERE identifier = @identifier AND slot = @slot', {
            ['@identifier'] = identifier,
            ['@slot'] = slot
        })
    else
        Framework.Database:Execute('UPDATE inventories SET count = @count WHERE identifier = @identifier AND slot = @slot', {
            ['@count'] = newCount,
            ['@identifier'] = identifier,
            ['@slot'] = slot
        })
    end

    return true, 'Item retiré'
end

function GetPlayerWeight(identifier)
    local totalWeight = 0
    
    -- Récupérer tous les items du joueur
    local playerItems = Framework.Database:Query('SELECT i.slot, i.item, i.count, it.weight FROM inventories i JOIN items it ON i.item = it.name WHERE i.identifier = ?', {
        identifier
    })
    
    if playerItems then
        for _, item in pairs(playerItems) do
            totalWeight = totalWeight + (item.weight * item.count)
        end
    end
    
    return totalWeight
end

function GetGroundItems(playerId)
    local groundItems = {}
    local playerCoords = GetEntityCoords(GetPlayerPed(playerId))

    -- TODO : Ajouter la manière dont sont gérés les items au sol (certainement via db)
    
    -- local itemsData = GetAllItemsData()
    -- for _, item in pairs(result or {}) do
    --     local itemData = itemsData[item.item]
    --     if itemData then
    --         item.label = itemData.label
    --         item.description = itemData.description
    --         item.weight = itemData.weight
    --         item.image = itemData.image
    --     end
    -- end
    
    -- return result or {}
    return {}
end

function GetPlayerData(playerId)
    local identifier = GetPlayerIdentifier(playerId, 0)
    
    return {
        weight = GetPlayerWeight(identifier),
        maxWeight = 50
    }
end

function RefreshPlayerInventory(player) 
    local identifier = GetPlayerIdentifier(player, 0)
    Citizen.Wait(50)

    local inventory = GetPlayerInventory(identifier)

    TriggerClientEvent('r_inventory:updateInventory', player, inventory)
    -- TriggerClientEvent('r_inventory:getGroundItems', player)
    TriggerClientEvent('r_inventory:updatePlayerData', player, GetPlayerData(player))
end

RegisterServerEvent('r_inventory:getPlayerData')
AddEventHandler('r_inventory:getPlayerData', function()
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    -- Récupérer les données du joueur depuis votre framework
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
    
    -- Enrichir l'inventaire avec les données des items
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
    
    RefreshPlayerInventory(source)
end)

-- Event pour récupérer un item au sol
RegisterServerEvent('r_inventory:pickupItem')
AddEventHandler('r_inventory:pickupItem', function(groundItemId, toSlot)
    print("test", groundItemId)
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
            print("slot:", toSlot)
            AddItemToInventory(identifier, groundItem[1].item, groundItem[1].count, toSlot, json.encode({}))
            
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

-- Event pour donner un item
RegisterServerEvent('r_inventory:giveItem')
AddEventHandler('r_inventory:giveItem', function(slot, itemName, count)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    -- TODO : Ajouter la logique pour donner un item
    print('Le joueur ' .. source .. ' donne ' .. count .. ' ' .. itemName)
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
    
    -- TODO: Ajouter la logique pour player -> ground et ground -> player
end)

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

RegisterServerEvent('r_inventory:GetPlayerModel')
AddEventHandler('r_inventory:GetPlayerModel', function()
    local source = source
    local ped = GetPlayerPed(source)

    local playerModel = GetEntityModel(ped)
    local playerData = {
        model = playerModel
    }

    TriggerClientEvent('inventory:getPlayerModel', source, playerData)
end)