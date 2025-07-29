local AdminMenu = nil
local currentPermissionLevel = 0
local isMenuOpen = false
local isMenuCreated = false
CurrentVehicle = nil

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
    TriggerServerEvent('r_admin:getPlayersList')
end

function OpenPlayerActionsMenu(targetId, targetName)
    local playerActionsMenu = MenuV:CreateMenu("Actions: " .. targetName, false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    playerActionsMenu:AddButton({
        icon = '➡️',
        label = 'Go to',
        description = 'Se téléporter vers ' .. targetName,
        select = function()
            TriggerServerEvent('r_admin:goToPlayer', targetId)
        end
    })

    playerActionsMenu:AddButton({
        icon = '⬅️',
        label = 'Bring',
        description = 'Amener ' .. targetName .. ' vers vous',
        select = function()
            local player = PlayerPedId()
            local playerCoords = GetEntityCoords(player)
            local playerHeading = GetEntityHeading(player)

            TriggerServerEvent('r_admin:bringPlayer', targetId, playerCoords, playerHeading)
        end
    })

    playerActionsMenu:AddButton({
        icon = '❤️',
        label = 'Heal',
        description = 'Soigner ' .. targetName,
        select = function()
            TriggerServerEvent('r_admin:healPlayer', targetId)
        end
    })

    playerActionsMenu:AddButton({
        icon = '🍗',
        label = 'Feed',
        description = 'Feed ' .. targetName,
        select = function()
            TriggerServerEvent('r_admin:feedPlayer', targetId)
        end
    })

    playerActionsMenu:AddButton({
        icon = '👢',
        label = 'Kick',
        description = 'Expulser ' .. targetName,
        select = function()
            GetReasonForAction('kick', targetId, targetName)
        end
    })

    playerActionsMenu:AddButton({
        icon = '🔨',
        label = 'Ban',
        description = 'Bannir ' .. targetName,
        select = function()
            GetReasonForAction('ban', targetId, targetName)
        end
    })

    playerActionsMenu:AddButton({
        icon = '🔫',
        label = 'Give weapon',
        description = 'Donner une arme à ' .. targetName,
        select = function()
            ShowWeaponCategories(targetId, targetName)
        end
    })

    playerActionsMenu:AddButton({
        icon = '💰',
        label = 'Give money',
        description = 'Donner de l\'argent cash à ' .. targetName,
        select = function()
            GetMoneyAmount(targetId, targetName, 'cash')
        end
    })

    playerActionsMenu:AddButton({
        icon = '🏦',
        label = 'Give bank money',
        description = 'Donner de l\'argent en banque à ' .. targetName,
        select = function()
            GetMoneyAmount(targetId, targetName, 'bank')
        end
    })

    playerActionsMenu:AddButton({
        icon = '🎒',
        label = 'Voir l\'inventaire',
        description = 'Consulter l\'inventaire de ' .. targetName,
        select = function()
            TriggerServerEvent('r_admin:viewInventory', targetId)
        end
    })

    playerActionsMenu:Open()
end

function OpenVehicleMainMenu()
    local vehicleMenu = MenuV:CreateMenu("Véhicule", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player)
    CurrentVehicle = vehicle

    -- Façon de vérifier si le véhicule est invincible
    local function isVehicleInvincible(vehicle)
        local bulletProof, fireProof, explosionProof, collisionProof, meleeProof, steamProof, p7, drownProof =
            GetEntityProofs(vehicle)
        return bulletProof and fireProof and explosionProof and collisionProof
    end

    vehicleMenu:AddButton({
        icon = '🚗',
        label = 'Liste des véhicules (spawn)',
        description = 'Faire apparaître un véhicule',
        select = function()
            ShowVehicleCategories()
        end
    })

    vehicleMenu:AddButton({
        icon = '🚗',
        label = 'Modifier le véhicule',
        description = 'Modifier le véhicule actuel',
        select = function()
            OpenVehicleModificationMenu()
        end
    })

    local invincibleCheckbox = vehicleMenu:AddCheckbox({
        icon = '🚗',
        label = 'Invincible',
        description = 'Rendre le véhicule invincible',
        value = isVehicleInvincible(CurrentVehicle),
    })

    invincibleCheckbox:On('update', function(uuid, key, currentValue, oldValue)
        if currentValue then
            SetEntityInvincible(CurrentVehicle, true)
            SetEntityProofs(CurrentVehicle, true, true, true, true, true, true, true, true)
        else
            SetEntityInvincible(CurrentVehicle, false)
            SetEntityProofs(CurrentVehicle, false, false, false, false, false, false, false, false)
        end
    end)

    vehicleMenu:AddButton({
        icon = '🔧',
        label = 'Réparer',
        description = 'Répare complètement le véhicule',
        select = function()
            RepairVehicle()
        end
    })

    vehicleMenu:AddButton({
        icon = '🧽',
        label = 'Nettoyer',
        description = 'Nettoie complètement le véhicule',
        select = function()
            ClearVehicle()
        end
    })

    vehicleMenu:AddButton({
        icon = '📋',
        label = 'Infos véhicule',
        description = 'Voir les détails du véhicule',
        select = function()
            GetVehicleDetails()
        end
    })

    vehicleMenu:On('close', function()
        CurrentVehicle = nil
    end)

    vehicleMenu:Open()
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
        icon = '🗺️',
        label = 'Se téléporter au waypoint',
        description = 'Aller au marqueur sur la carte',
        select = function()
            TeleportToWaypoint()
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
            ShowWeaponCategories()
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

RegisterNetEvent('r_admin:openMenu')
AddEventHandler('r_admin:openMenu', function(permissionLevel)
    CreateAdminMenu(permissionLevel)
    if AdminMenu ~= nil then
        AdminMenu:Open()
        isMenuOpen = true
    end
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
