Framework.Inventory = {
    items = {},
    shops = {},
    drops = {},
    maxWeight = 50000,  -- 50kg en grammes
    maxSlots = 50,
    decayEnabled = true,
    decayRate = 0.1  -- 10% par jour
}

-- Initialisation de l'inventaire
function Framework.Inventory:Init()
    self:LoadItems()
    self:LoadShops()
    self:StartDecaySystem()
    Framework.Debug:Info('Inventory system initialized')
end

-- Charge les objets depuis la base de données
function Framework.Inventory:LoadItems()
    local items = Framework.Database:Query('SELECT * FROM items')
    
    if items then
        for _, item in pairs(items) do
            self.items[item.name] = {
                name = item.name,
                label = item.label,
                weight = item.weight,
                rare = item.rare == 1,
                canRemove = item.canRemove == 1,
                canUse = item.canUse == 1,
                shouldClose = item.shouldClose == 1,
                combinable = item.combinable and json.decode(item.combinable) or nil,
                description = item.description,
                image = item.image,
                decay = item.decay or 0,
                category = item.category or 'misc'
            }
        end
    end
    
    Framework.Debug:Info(('Loaded %d items'):format(Framework.Utils:TableSize(self.items)))
end

-- Charge les magasins
function Framework.Inventory:LoadShops()
    local shops = Framework.Database:Query('SELECT * FROM shops')
    
    if shops then
        for _, shop in pairs(shops) do
            self.shops[shop.name] = {
                name = shop.name,
                label = shop.label,
                coords = json.decode(shop.coords),
                items = json.decode(shop.items),
                blip = shop.blip and json.decode(shop.blip) or nil,
                job = shop.job,
                jobGrade = shop.jobGrade or 0
            }
        end
    end
    
    Framework.Debug:Info(('Loaded %d shops'):format(Framework.Utils:TableSize(self.shops)))
end

-- Get un objet
function Framework.Inventory:GetItem(name)
    return self.items[name]
end

-- Ajoute un objet à l'inventaire d'un joueur
function Framework.Inventory:AddItem(source, item, count, metadata)
    local player = Framework.Players:GetPlayer(source)
    if not player then return false end
    
    local itemData = self:GetItem(item)
    if not itemData then
        Framework.Debug:Error(('Item %s not found'):format(item))
        return false
    end
    
    count = count or 1
    metadata = metadata or {}
    
    local totalWeight = self:GetInventoryWeight(player.inventory)
    local itemWeight = itemData.weight * count
    
    if totalWeight + itemWeight > self.maxWeight then
        Framework.Events:TriggerClient(source, 'framework:inventory:notify', 'Inventaire plein', 'error')
        return false
    end
    
    local usedSlots = self:GetUsedSlots(player.inventory)
    if usedSlots >= self.maxSlots then
        Framework.Events:TriggerClient(source, 'framework:inventory:notify', 'Plus de place dans l\'inventaire', 'error')
        return false
    end
    
    local slot = self:FindSlotFor(player.inventory, item, count)
    if not slot then
        Framework.Debug:Error(('No slot found for item %s'):format(item))
        return false
    end
    
    if player.inventory[slot] then
        player.inventory[slot].count = player.inventory[slot].count + count
    else
        player.inventory[slot] = {
            name = item,
            count = count,
            metadata = metadata,
            slot = slot,
            created = os.time()
        }
    end
    
    player:SaveInventory()
    
    Framework.Events:TriggerClient(source, 'framework:inventory:notify', 
        ('Vous avez reçu %dx %s'):format(count, itemData.label), 'success')
    
    Framework.Events:Trigger('framework:inventory:itemAdded', source, item, count, metadata)
    
    return true
end

-- Retire un objet de l'inventaire d'un joueur
function Framework.Inventory:RemoveItem(source, item, count, metadata)
    local player = Framework.Players:GetPlayer(source)
    if not player then return false end
    
    local itemData = self:GetItem(item)
    if not itemData then return false end
    
    count = count or 1
    
    local slot = self:FindItemSlot(player.inventory, item, count, metadata)
    if not slot then
        Framework.Debug:Error(('Item %s not found in inventory'):format(item))
        return false
    end
    
    if player.inventory[slot].count > count then
        player.inventory[slot].count = player.inventory[slot].count - count
    else
        player.inventory[slot] = nil
    end
    
    -- Sauvegarder l'inventaire
    player:SaveInventory()
    
    Framework.Events:TriggerClient(source, 'framework:inventory:notify', 
        ('Vous avez perdu %dx %s'):format(count, itemData.label), 'error')
    
    Framework.Events:Trigger('framework:inventory:itemRemoved', source, item, count, metadata)
    
    return true
end

-- Utilise un objet
function Framework.Inventory:UseItem(source, item, metadata)
    local player = Framework.Players:GetPlayer(source)
    if not player then return false end
    
    local itemData = self:GetItem(item)
    if not itemData then return false end
    
    if not itemData.canUse then
        Framework.Events:TriggerClient(source, 'framework:inventory:notify', 
            'Cet objet ne peut pas être utilisé', 'error')
        return false
    end
    
    if not self:HasItem(source, item, 1) then
        Framework.Events:TriggerClient(source, 'framework:inventory:notify', 
            'Vous n\'avez pas cet objet', 'error')
        return false
    end
    
    Framework.Events:Trigger('framework:inventory:useItem', source, item, metadata)
    
    if itemData.shouldClose then
        self:RemoveItem(source, item, 1, metadata)
    end
    
    return true
end

-- Vérifie si un joueur possède un objet
function Framework.Inventory:HasItem(source, item, count)
    local player = Framework.Players:GetPlayer(source)
    if not player then return false end
    
    count = count or 1
    local totalCount = 0
    
    for _, inventoryItem in pairs(player.inventory) do
        if inventoryItem.name == item then
            totalCount = totalCount + inventoryItem.count
        end
    end
    
    return totalCount >= count
end

-- Get le poids total de l'inventaire
function Framework.Inventory:GetInventoryWeight(inventory)
    local totalWeight = 0
    
    for _, item in pairs(inventory) do
        local itemData = self:GetItem(item.name)
        if itemData then
            totalWeight = totalWeight + (itemData.weight * item.count)
        end
    end
    
    return totalWeight
end

-- Get le nombre de slots utilisés
function Framework.Inventory:GetUsedSlots(inventory)
    local usedSlots = 0
    
    for _ in pairs(inventory) do
        usedSlots = usedSlots + 1
    end
    
    return usedSlots
end

-- Trouve un slot pour un objet
function Framework.Inventory:FindSlotFor(inventory, item, count)
    -- Vérifie si l'objet peut être empilé
    for slot, inventoryItem in pairs(inventory) do
        if inventoryItem.name == item then
            return slot
        end
    end
    
    -- Trouve un slot libre
    for i = 1, self.maxSlots do
        if not inventory[i] then
            return i
        end
    end
    
    return nil
end

-- Trouve le slot d'un objet spécifique
function Framework.Inventory:FindItemSlot(inventory, item, count, metadata)
    for slot, inventoryItem in pairs(inventory) do
        if inventoryItem.name == item and inventoryItem.count >= count then
            if metadata then
                local metaMatch = true
                for key, value in pairs(metadata) do
                    if inventoryItem.metadata[key] ~= value then
                        metaMatch = false
                        break
                    end
                end
                if metaMatch then
                    return slot
                end
            else
                return slot
            end
        end
    end
    
    return nil
end

-- Drop un item
function Framework.Inventory:DropItem(source, item, count, metadata)
    local player = Framework.Players:GetPlayer(source)
    if not player then return false end
    
    if not self:RemoveItem(source, item, count, metadata) then
        return false
    end
    
    local playerPed = GetPlayerPed(source)
    local coords = GetEntityCoords(playerPed)
    
    local dropId = Framework.Utils:GenerateId()
    self.drops[dropId] = {
        id = dropId,
        coords = coords,
        item = item,
        count = count,
        metadata = metadata,
        created = os.time(),
        source = source
    }
    
    return true
end

-- Ramasse un objet
function Framework.Inventory:PickupItem(source, dropId)
    local drop = self.drops[dropId]
    if not drop then return false end
    
    -- Vérifie la distance
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - drop.coords)
    
    if distance > 3.0 then
        TriggerClientEvent(source, 'framework:inventory:notify', 'Vous êtes trop loin', 'error')
        return false
    end
    
    -- Ajoute l'objet à l'inventaire
    if self:AddItem(source, drop.item, drop.count, drop.metadata) then
        -- Supprime le drop
        self.drops[dropId] = nil
        
        return true
    end
    
    return false
end

-- Get les stats de l'inventaire
function Framework.Inventory:GetStats()
    return {
        totalItems = Framework.Utils:TableSize(self.items),
        totalShops = Framework.Utils:TableSize(self.shops),
        activeDrops = Framework.Utils:TableSize(self.drops),
        decayEnabled = self.decayEnabled,
        maxWeight = self.maxWeight,
        maxSlots = self.maxSlots
    }
end

-- Events
Framework.Events:Register('framework:inventory:useItem', function(source, item, metadata)
    Framework.Inventory:UseItem(source, item, metadata)
end)

Framework.Events:Register('framework:inventory:dropItem', function(source, item, count, metadata)
    Framework.Inventory:DropItem(source, item, count, metadata)
end)

Framework.Events:Register('framework:inventory:pickupItem', function(source, dropId)
    Framework.Inventory:PickupItem(source, dropId)
end)

print('^2[Rowden Framework]^0 Inventory system loaded')