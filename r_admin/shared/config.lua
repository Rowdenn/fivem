AdminConfig = {}

-- Configuration des permissions (3 niveaux uniquement)
AdminConfig.Permissions = {
    MODERATOR = 1, -- Modérateur
    ADMIN = 2,     -- Administrateur
    OWNER = 3      -- Propriétaire
}

-- Configuration du menu
AdminConfig.Menu = {
    openKey = 167,  -- F6
    closeKey = 177, -- Backspace
}

-- Configuration des actions par niveau de permission
AdminConfig.MenuActions = {
    [1] = {
        'goto',
        'bring',
        'feed',
        'heal',
        'revive',
        'spectate_player',
        'kick_player',
        'freeze_player',
        'noclip',
        'spawn_vehicle'
    },
    [2] = {
        'goto',
        'bring',
        'feed',
        'heal',
        'revive',
        'spectate_player',
        'kick_player',
        'freeze_player',
        'noclip',
        'spawn_vehicle',
        'ban_player',
        'fix_vehicle',
        'god_mode',
        'invisible',
    },
    [3] = {
        'goto',
        'bring',
        'spectate_player',
        'kick_player',
        'freeze_player',
        'noclip',
        'ban_player',
        'spawn_vehicle',
        'fix_vehicle',
        'god_mode',
        'invisible',
        'revive_player',
        'feed',
        'heal',
        'give_money',
        'server_management',
        'weather_control',
        'time_control'
    }
}

AdminConfig.CommandsPermissions = {
    [AdminConfig.Permissions.MODERATOR] = {
        'getcoords',
        'tp'
    }
}

-- Messages d'administration
AdminConfig.Messages = {
    no_permission = "Vous n'avez pas les permissions pour utiliser cette commande",
    player_not_found = "Joueur introuvable",
    action_success = "Action effectuée avec succès"
}

AdminConfig.StandardCarColors = {
    -- Couleurs Standards
    [0] = "Black",
    [1] = "Graphite",
    [2] = "Black Steel",
    [3] = "Dark Steel",
    [4] = "Silver",
    [5] = "Bluish Silver",
    [6] = "Rolled Steel",
    [7] = "Shadow Silver",
    [8] = "Stone Silver",
    [9] = "Midnight Silver",
    [10] = "Cast Iron Silver",
    [11] = "Anhracite Black",
    [27] = "Red",
    [28] = "Torino Red",
    [29] = "Formula Red",
    [30] = "Blaze Red",
    [31] = "Grace Red",
    [32] = "Garnet Red",
    [33] = "Sunset Red",
    [34] = "Cabernet Red",
    [35] = "Candy Red",
    [36] = "Sunrise Orange",
    [38] = "Orange",
    [49] = "Dark Green",
    [50] = "Racing Green",
    [51] = "Sea Green",
    [52] = "Olive Green",
    [53] = "Bright Green",
    [54] = "Gasoline Green",
    [61] = "Galaxy Blue",
    [62] = "Dark Blue",
    [63] = "Saxon Blue",
    [64] = "Blue",
    [65] = "Mariner Blue",
    [66] = "Harbor Blue",
    [67] = "Diamond Blue",
    [68] = "Surf Blue",
    [69] = "Nautical Blue",
    [70] = "Ultra Blue",
    [71] = "Schafter Purple",
    [72] = "Spinnaker Purple",
    [73] = "Racing Blue",
    [74] = "Light Blue",
    [88] = "Yellow",
    [89] = "Race Yellow",
    [90] = "Bronze",
    [91] = "Dew Yellow",
    [92] = "Lime Green",
    [94] = "Feltzer Brown",
    [95] = "Creeen Brown",
    [96] = "Chocolate Brown",
    [97] = "Maple Brown",
    [98] = "Saddle Brown",
    [99] = "Straw Brown",
    [100] = "Moss Brown",
    [101] = "Bison Brown",
    [102] = "Woodbeech Brown",
    [103] = "Beechwood Brown",
    [104] = "Sienna Brown",
    [105] = "Sandy Brown",
    [106] = "Bleached Brown",
    [107] = "Cream",
    [111] = "Ice White",
    [112] = "Frost White",
    [135] = "Hot Pink",
    [136] = "Salmon Pink",
    [137] = "Pfsiter Pink",
    [138] = "Bright Orange",
    [141] = "Midnight Blue",
    [142] = "Midnight Purple",
    [143] = "Wine Red",
    [145] = "Bright Purple",
    [147] = "Carbon Black",
    [150] = "Lava Red"
}

AdminConfig.MatCarColors = {
    [12] = "Matte Black",
    [13] = "Matte Gray",
    [14] = "Matte Light Gray",
    [39] = "Matte Red",
    [40] = "Matte Dark Red",
    [41] = "Matte Orange",
    [42] = "Matte Yellow",
    [55] = "Matte Lime Green",
    [82] = "Matte Dark Blue",
    [83] = "Matte Blue",
    [84] = "Matte Midnight Blue",
    [128] = "Matte Green",
    [131] = "Matte Ice White",
    [148] = "Matte Schafter Purple",
    [149] = "Matte Midnight Purple",
    [151] = "Matte Frost Green",
    [152] = "Matte Olive Darb",
    [154] = "Matte Desert Tan",
    [155] = "Matte Dark Earth",
}

AdminConfig.MetalicCarColors = {
    [117] = "Brushed Steel",
    [118] = "Brushed Black Steel",
    [119] = "Brushed Aluminum",
    [158] = "Pure Gold",
    [159] = "Brushed Gold"
}
