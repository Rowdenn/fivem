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
    { coords = vec3(236.515, 219.642, 106.286) },
}

GlobalConfig.Bank.Banks = {
    {
        name = 'Banque de Vinewood',
        coords = vec3(253.987, 222.464, 106.286),
    },
}

GlobalConfig.Bank.Bankers = {
    {
        coords = vec3(253.980, 222.509, 106.287),
        heading = 163.230,
        model = "a_m_y_business_01"
    },
    {
        coords = vec3(248.816, 224.372, 106.287),
        heading = 159.282,
        model = "a_m_y_business_01"
    },
}
