Config = {}

Config.Debug = true
Config.CheckForUpdates = true
Config.locales = 'fr'

Config.Database = {
    host = 'localhost',
    database = 'framework',
    username = 'root',
    password = '',
    charset = 'utf8mb4',
    connectionLimit = 10
}

Config.Logging = {
    enabled = true,
    level = 'info', -- debug, info, warn, error
    maxFiles = 10,
    maxFilesSize = 10 * 1024 * 1024,
    logToFile = true,
    logToConsole = true
}

Config.Player = {
    startingMoney = 5000,
    startingBank = 0,
    enableMultiCharacter = true,
    maxCharacters = 5
}

Config.Inventory = {
    maxWeight = 30000, -- grammes
    maxSlots = 50,
    enableDrop = true,
    enablePickup = true,
    enableGiveItem = true
}

Config.Economy = {
    startingJob = 'unemployed',
    defaultSalary = 0,
    enableSalary = true,
    salaryInterval = 30, -- minutes
    enableTaxes = true,
    taxRate = 0.15 -- 15%
}

Config.Vehicules = {
    enableFuel = true,
    enableKeys = true
}

Config.Permissions = {
    defaultGroup = 'user',
    enableInheritance = true,
    groups = {
        ['superadmin'] = {
            inherit = {},
            permissions = {'*'}
        },
        ['admin'] = {
            inherit = {'user'},
            permissions = {
                'admin.ban',
                'admin.kick',
                'admin.teleport',
                'admin.noclip',
                'admin.god',
                'admin.spectate',
            }
        },
        ['user '] = {
            inherit = {},
            permissions = {
                'user.play',
                'user.chat'
            }
        }
    }
}

Config.Events = {
    enableAntiSpam = true,
    maxEventsPerSecond = 10,
    enableValidation = true,
    enableLoggig = true
}

Config.UI = {
    enableNotifications = true,
    notificationPosition = 'top-right',
    defaultTheme = 'dark',
    enableAnimations = true
}

Config.Security = {
    enableAntiCheat = true,
    enableInputValidation = true,
    enableRateLimit = true,
    enableEncryption = true,
}

Config.Backup = {
    enabled = true,
    interval = 300, -- 5 minutes
    maxBackups = 10,
    backupPath = 'backups/'
}

Config.Discord = {
    enabled = false,
    webhooks = {
        general = '',
        admin = '',
        economy = '',
        bans = ''
    }
}

Config.Modules = {
    enabledModules = {
        'player',
        'inventory',
        'economy',
        'vehicle',
        'job',
        'gang',
        'housing',
        'shops',
    },
    autoLoad = true,
    requiredModules = {
        'player',
        'inventory',
        'economy'
    }
}

Config.Locales = {
    ['fr'] = {
        ['framework_loaded'] = 'Framework chargé avec succès',
        ['player_connected'] = 'Joueur connecté',
        ['player_disconnected'] = 'Joueur déconnecté',
        ['insufficient_permissions'] = 'Permissions insuffisantes',
        ['invalid_arguments'] = 'Arguments invalides',
        ['database_error'] = 'Erreur de base de données',
        ['module_loaded'] = 'Module chargé: %s',
        ['module_error'] = 'Erreur lors du chargement du module: %s',

    -- Messages d'erreur
        ['error_occurred'] = 'Une erreur s\'est produite',
        ['player_not_found'] = 'Joueur non trouvé',
        ['invalid_amount'] = 'Montant invalide',
        ['insufficient_funds'] = 'Fonds insuffisants',
        ['item_not_found'] = 'Objet non trouvé',
        ['inventory_full'] = 'Inventaire plein',
        ['vehicle_not_found'] = 'Véhicule non trouvé',
        ['access_denied'] = 'Accès refusé',
        
        -- Messages de succès
        ['operation_successful'] = 'Opération réussie',
        ['money_added'] = 'Argent ajouté: $%s',
        ['money_removed'] = 'Argent retiré: $%s',
        ['item_added'] = 'Objet ajouté: %s (x%s)',
        ['item_removed'] = 'Objet retiré: %s (x%s)',
        ['vehicle_spawned'] = 'Véhicule spawn: %s',
        ['saved_successfully'] = 'Sauvegarde réussie'
    }
}

Config.Version = {
    major = 1,
    minor = 0,
    patch = 0,
    build = 1,
    string = '0.0.1-alpha'
}

Config.Performance = {
    enableOptimizations = true,
    cacheSize = 1000,
    cleanupInterval = 300, -- 5 minutes
    enableProfiler = Config.Debug,
    maxExecutionTime = 50, -- millisecondes
    enableLazyLoading = true
}

print('^2[Rowden Framework]^0 Configuration loaded successfully')