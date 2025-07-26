local AdminMenu = nil
local currentPermissionLevel = 0
local isMenuOpen = false
local isMenuCreated = false

function ShowNotification(message, type)
    local player = source
    exports['r_notify']:ShowNotification(player, {
        message = message,
        type = type,
        duration = 5000
    })
end

function ShowPlayerList()
    TriggerServerEvent('r_admin:getPlayerList')
end

function CreateAdminMenu(permissionLevel)
    if isMenuCreated and currentPermissionLevel == permissionLevel then
        return
    end

    currentPermissionLevel = permissionLevel
    isMenuCreated = true

    AdminMenu = MenuV:CreateMenu('Administration', false, 'topright', 255, 0, 0, 'size-125', 'interaction_bgd',
        'commonmenu', false, 'native')

    if permissionLevel >= 1 then
        -- Section Joueurs
        AdminMenu:AddButton({
            icon = '👤',
            label = 'Joueurs',
            description = 'Gestion des joueurs connectés',
            select = function()
                OpenPlayersMainMenu()
            end
        })

        -- Section Véhicule
        AdminMenu:AddButton({
            icon = '🚗',
            label = 'Véhicule',
            description = 'Gestion des véhicules',
            select = function()
                OpenVehicleMainMenu()
            end
        })

        -- Section Monde
        AdminMenu:AddButton({
            icon = '🌍',
            label = 'Monde',
            description = 'Modifier l\'environnement du serveur',
            select = function()
                OpenWorldMenu()
            end
        })

        -- Section Utilitaires
        AdminMenu:AddButton({
            icon = '🔧',
            label = 'Utilitaires',
            description = 'Outils personnels d\'administration',
            select = function()
                OpenUtilitiesMenu()
            end
        })
    end

    AdminMenu:Open()
end

function OpenPlayersMainMenu()
    local playersMenu = MenuV:CreateMenu("Joueurs", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    -- Génère la liste dynamique des joueurs
    local players = GetActivePlayers()
    for _, playerId in ipairs(players) do
        local playerName = GetPlayerName(playerId)
        local playerServerId = GetPlayerServerId(playerId)

        playersMenu:AddButton({
            icon = '👤',
            label = playerName .. ' [' .. playerServerId .. ']',
            description = 'Actions sur ' .. playerName,
            select = function()
                OpenPlayerActionsMenu(playerServerId, playerName)
            end
        })
    end

    playersMenu:Open()
end

function OpenPlayerActionsMenu(targetId, targetName)
    local playerActionsMenu = MenuV:CreateMenu("Actions: " .. targetName, false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    playerActionsMenu:AddButton({
        icon = '➡️',
        label = 'Go to',
        description = 'Se téléporter vers ' .. targetName,
        select = function()
            TriggerServerEvent('admin:gotoPlayer', targetId)
        end
    })

    playerActionsMenu:AddButton({
        icon = '⬅️',
        label = 'Bring',
        description = 'Amener ' .. targetName .. ' vers vous',
        select = function()
            TriggerServerEvent('admin:bringPlayer', targetId)
        end
    })

    playerActionsMenu:AddButton({
        icon = '❤️',
        label = 'Heal',
        description = 'Soigner ' .. targetName,
        select = function()
            TriggerServerEvent('admin:healPlayer', targetId)
        end
    })

    playerActionsMenu:AddButton({
        icon = '👢',
        label = 'Kick',
        description = 'Expulser ' .. targetName,
        select = function()
            -- GetReasonForAction('kick', targetId, targetName)
        end
    })

    playerActionsMenu:AddButton({
        icon = '🔨',
        label = 'Ban',
        description = 'Bannir ' .. targetName,
        select = function()
            -- GetReasonForAction('ban', targetId, targetName)
        end
    })

    playerActionsMenu:AddButton({
        icon = '🔫',
        label = 'Give weapon',
        description = 'Donner une arme à ' .. targetName,
        select = function()
            -- GetWeaponForPlayer(targetId, targetName)
        end
    })

    playerActionsMenu:AddButton({
        icon = '💰',
        label = 'Give money',
        description = 'Donner de l\'argent cash à ' .. targetName,
        select = function()
            -- GetMoneyAmount(targetId, targetName, 'cash')
        end
    })

    playerActionsMenu:AddButton({
        icon = '🏦',
        label = 'Give bank money',
        description = 'Donner de l\'argent en banque à ' .. targetName,
        select = function()
            -- GetMoneyAmount(targetId, targetName, 'bank')
        end
    })

    playerActionsMenu:AddButton({
        icon = '🎒',
        label = 'Voir l\'inventaire',
        description = 'Consulter l\'inventaire de ' .. targetName,
        select = function()
            TriggerServerEvent('admin:viewInventory', targetId)
        end
    })

    playerActionsMenu:Open()
end

function OpenVehicleMainMenu()
    local vehicleMenu = MenuV:CreateMenu("Véhicule", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    vehicleMenu:AddButton({
        icon = '🚗',
        label = 'Liste des véhicules (spawn)',
        description = 'Faire apparaître un véhicule',
        select = function()
            OpenVehicleCategoriesMenu()
        end
    })

    vehicleMenu:AddButton({
        icon = '🎨',
        label = 'Modifier le véhicule',
        description = 'Personnaliser votre véhicule actuel',
        select = function()
            OpenVehicleModificationMenu()
        end
    })

    vehicleMenu:Open()
end

function OpenVehicleCategoriesMenu()
    local categoriesMenu = MenuV:CreateMenu("Catégories de véhicules", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    categoriesMenu:AddButton({
        icon = '🏎️',
        label = 'Sportives',
        description = 'Véhicules de sport',
        select = function()
            -- OpenVehicleListMenu('sportives')
        end
    })

    categoriesMenu:AddButton({
        icon = '🏁',
        label = 'Sportives Classic',
        description = 'Voitures de sport classiques',
        select = function()
            -- OpenVehicleListMenu('sportclassic')
        end
    })

    categoriesMenu:AddButton({
        icon = '🚙',
        label = 'Citadines',
        description = 'Véhicules urbains',
        select = function()
            -- OpenVehicleListMenu('compacts')
        end
    })

    categoriesMenu:AddButton({
        icon = '🚜',
        label = 'Off-Road',
        description = 'Véhicules tout-terrain',
        select = function()
            -- OpenVehicleListMenu('offroad')
        end
    })

    categoriesMenu:Open()
end

function OpenVehicleModificationMenu()
    local modMenu = MenuV:CreateMenu("Modifier véhicule", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    modMenu:AddButton({
        icon = '🎨',
        label = 'Couleur',
        description = 'Changer la couleur du véhicule',
        select = function()
            -- OpenColorMenu()
        end
    })

    modMenu:AddButton({
        icon = '⭕',
        label = 'Jantes',
        description = 'Modifier les jantes',
        select = function()
            -- OpenWheelsMenu()
        end
    })

    modMenu:AddButton({
        icon = '🛡️',
        label = 'Pare-choc avant',
        description = 'Changer le pare-choc avant',
        select = function()
            -- OpenBumperMenu('front')
        end
    })

    modMenu:Open()
end

function OpenWorldMenu()
    local worldMenu = MenuV:CreateMenu("Monde", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    worldMenu:AddButton({
        icon = '🌤️',
        label = 'Modifier la météo',
        description = 'Changer les conditions météorologiques',
        select = function()
            -- OpenWeatherMenu()
        end
    })

    worldMenu:AddButton({
        icon = '🕐',
        label = 'Changer l\'heure',
        description = 'Modifier l\'heure du serveur',
        select = function()
            -- GetTimeForServer()
        end
    })

    worldMenu:Open()
end

function OpenUtilitiesMenu()
    local utilitiesMenu = MenuV:CreateMenu("Utilitaires", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    utilitiesMenu:AddButton({
        icon = '📍',
        label = 'Se téléporter à des coordonnées',
        description = 'Entrer des coordonnées manuellement',
        select = function()
            -- GetCoordinatesForTeleport()
        end
    })

    utilitiesMenu:AddButton({
        icon = '🗺️',
        label = 'Se téléporter au waypoint',
        description = 'Aller au marqueur sur la carte',
        select = function()
            -- TeleportToWaypoint()
        end
    })

    utilitiesMenu:AddButton({
        icon = '🛡️',
        label = 'Mode invincible',
        description = 'Activer/désactiver l\'invincibilité',
        select = function()
            -- ToggleGodMode()
        end
    })

    utilitiesMenu:AddButton({
        icon = '🔫',
        label = 'Give une arme',
        description = 'Vous donner une arme',
        select = function()
            -- GetWeaponForSelf()
        end
    })

    utilitiesMenu:AddButton({
        icon = '💰',
        label = 'Give money',
        description = 'Vous donner de l\'argent cash',
        select = function()
            -- GetMoneyAmountForSelf('cash')
        end
    })

    utilitiesMenu:AddButton({
        icon = '🏦',
        label = 'Give bank money',
        description = 'Vous donner de l\'argent en banque',
        select = function()
            -- GetMoneyAmountForSelf('bank')
        end
    })

    utilitiesMenu:Open()
end

-- Event pour recevoir la liste des joueurs
RegisterNetEvent('r_admin:receivePlayerList')
AddEventHandler('r_admin:receivePlayerList', function(players)
    local playerListMenu = MenuV:CreateMenu("Joueurs connectés", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    for _, player in pairs(players) do
        playerListMenu:AddButton({
            label = player.name .. ' (ID: ' .. player.id .. ')',
            description = 'Sélectionner pour les actions',
            select = function()
                OpenPlayerActionsMenu(player)
            end
        })
    end

    playerListMenu:Open()
end)

RegisterNetEvent('r_admin:openMenu')
AddEventHandler('r_admin:openMenu', function(permissionLevel)
    CreateAdminMenu(permissionLevel)
    if AdminMenu ~= nil then
        AdminMenu:Open()
        isMenuOpen = true
    end
end)

RegisterNetEvent('r_admin:showNotification')
AddEventHandler('r_admin:showNotification', function(message, type)
    ShowNotification(message, type)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if IsControlJustReleased(0, 167) and not isMenuOpen then
            TriggerServerEvent('r_admin:checkPermissions')
        end

        if IsControlJustReleased(0, 177) and isMenuOpen then
            if AdminMenu then
                AdminMenu:Close()
                isMenuOpen = false
            end
        end
    end
end)
