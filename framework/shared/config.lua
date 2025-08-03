GlobalConfig = {}

--------------------------------
-- INVENTORY
--------------------------------

GlobalConfig.Inventory = {}

GlobalConfig.Inventory.MaxWeight = 50000
GlobalConfig.Inventory.MaxInventorySlots = 120
GlobalConfig.Inventory.GroundInventoryDistance = 5.0
GlobalConfig.Inventory.GroundInventoryTime = 500

GlobalConfig.Inventory.Keys = {
    OpenInventory = 37, -- tab
    QuickUse = {
        [1] = 157,
        [2] = 158,
        [3] = 160,
        [4] = 164,
        [5] = 165,
    }
}

GlobalConfig.Inventory.ClothingSlots = {
    'hat',
    'glasses',
    'mask',
    'chain',
    'shirt',
    'bag',
    'watch',
    'pants',
    'bracelet',
    'shoes',
}

GlobalConfig.Inventory.Categories = {
    'weapon',
    'food',
    'drink',
    'clothing',
    'tool',
    'misc',
}

GlobalConfig.Inventory.UsableItems = {
    'bread',
    'water',
    'phone',
    'bandage'
}
