local Framework = exports['framework']:GetFramework()

-- Fonction pour obtenir l'inventaire d'un joueur
function GetPlayerInventory(identifier)
    local inventory = {}
    
    -- Requête SQL pour récupérer l'inventaire
    local result = Framework.Database:Query('SELECT * FROM inventories WHERE identifier = @identifier ORDER BY slot ASC', {
        ['@identifier'] = identifier
    })
    
    for _, item in pairs(result) do
        local itemData = GetItemData(item.item)

        local inventoryItem = {
            item = item.item,
            count = item.count,
            metadata = json.decode(item.metadata or '{}'),
            slot = item.slot,
            image = itemData and itemData.image or 'default.png',
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