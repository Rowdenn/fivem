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

--------------------------------
-- BANK
--------------------------------

GlobalConfig.Bank = {}

GlobalConfig.Bank.ATMs = {
    { coords = vector3(236.515, 219.642, 106.286) },
}

GlobalConfig.Bank.Banks = {
    {
        name = 'Banque de Vinewood',
        coords = vector3(253.987, 222.464, 106.286),
        heading = 160.979,
        ped = "a_m_y_business_01"
    },
}
