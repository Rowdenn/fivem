Config = {}

-- Configuration des permissions (3 niveaux uniquement)
Config.Permissions = {
    MODERATOR = 1, -- Modérateur
    ADMIN = 2,     -- Administrateur
    OWNER = 3      -- Propriétaire
}

-- Configuration du menu
Config.Menu = {
    openKey = 167,  -- F6
    closeKey = 177, -- Backspace
}

-- Configuration des actions par niveau de permission
Config.MenuActions = {
    [Config.Permissions.MODERATOR] = {
        'teleport_to_player',
        'teleport_player_to_me',
        'spectate_player',
        'kick_player',
        'freeze_player',
        'noclip'
    },
    [Config.Permissions.ADMIN] = {
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
    [Config.Permissions.OWNER] = {
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

-- Messages d'administration
Config.Messages = {
    no_permission = "Vous n'avez pas les permissions pour utiliser cette commande",
    player_not_found = "Joueur introuvable",
    action_success = "Action effectuée avec succès"
}
