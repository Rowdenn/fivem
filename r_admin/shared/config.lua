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
    [AdminConfig.Permissions.MODERATOR] = {
        'teleport_to_player',
        'teleport_player_to_me',
        'spectate_player',
        'kick_player',
        'freeze_player',
        'noclip'
    },
    [AdminConfig.Permissions.ADMIN] = {
        'teleport_to_player',
        'teleport_player_to_me',
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
        'heal_player'
    },
    [AdminConfig.Permissions.OWNER] = {
        'teleport_to_player',
        'teleport_player_to_me',
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
        'heal_player',
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
