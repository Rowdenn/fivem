-- ! Supprimer le système de munitions lorsque les items des types de chargeur sera fait

local WeaponCategories = {
    {
        name = "Armes de poing",
        icon = "🔫",
        weapons = {
            { name = "Pistolet",           hash = "WEAPON_PISTOL",        ammo = 250 },
            { name = "Pistolet Mk II",     hash = "WEAPON_PISTOL_MK2",    ammo = 250 },
            { name = "Pistolet de combat", hash = "WEAPON_COMBATPISTOL",  ammo = 250 },
            { name = "Pistolet AP",        hash = "WEAPON_APPISTOL",      ammo = 250 },
            { name = "Pistolet SNS",       hash = "WEAPON_SNSPISTOL",     ammo = 250 },
            { name = "Pistolet lourd",     hash = "WEAPON_HEAVYPISTOL",   ammo = 250 },
            { name = "Pistolet vintage",   hash = "WEAPON_VINTAGEPISTOL", ammo = 250 },
            { name = "Révolver",           hash = "WEAPON_REVOLVER",      ammo = 250 },
            { name = "Révolver Mk II",     hash = "WEAPON_REVOLVER_MK2",  ammo = 250 },
            { name = "Double Action",      hash = "WEAPON_DOUBLEACTION",  ammo = 250 },
            { name = "Pistolet céramique", hash = "WEAPON_CERAMICPISTOL", ammo = 250 },
            { name = "Pistolet marine",    hash = "WEAPON_NAVYREVOLVER",  ammo = 250 }
        }
    },
    {
        name = "Mitraillettes",
        icon = "🔫",
        weapons = {
            { name = "Micro SMG",     hash = "WEAPON_MICROSMG",     ammo = 500 },
            { name = "SMG",           hash = "WEAPON_SMG",          ammo = 500 },
            { name = "SMG Mk II",     hash = "WEAPON_SMG_MK2",      ammo = 500 },
            { name = "SMG d'assaut",  hash = "WEAPON_ASSAULTSMG",   ammo = 500 },
            { name = "PDW de combat", hash = "WEAPON_COMBATPDW",    ammo = 500 },
            { name = "MG compact",    hash = "WEAPON_COMPACTRIFLE", ammo = 500 },
            { name = "Mini SMG",      hash = "WEAPON_MINISMG",      ammo = 500 }
        }
    },
    {
        name = "Fusils d'assaut",
        icon = "🔫",
        weapons = {
            { name = "Fusil d'assaut",       hash = "WEAPON_ASSAULTRIFLE",       ammo = 600 },
            { name = "Fusil d'assaut Mk II", hash = "WEAPON_ASSAULTRIFLE_MK2",   ammo = 600 },
            { name = "Carabine",             hash = "WEAPON_CARBINERIFLE",       ammo = 600 },
            { name = "Carabine Mk II",       hash = "WEAPON_CARBINERIFLE_MK2",   ammo = 600 },
            { name = "Fusil avancé",         hash = "WEAPON_ADVANCEDRIFLE",      ammo = 600 },
            { name = "Fusil spécial",        hash = "WEAPON_SPECIALCARBINE",     ammo = 600 },
            { name = "Fusil spécial Mk II",  hash = "WEAPON_SPECIALCARBINE_MK2", ammo = 600 },
            { name = "Fusil bullpup",        hash = "WEAPON_BULLPUPRIFLE",       ammo = 600 },
            { name = "Fusil bullpup Mk II",  hash = "WEAPON_BULLPUPRIFLE_MK2",   ammo = 600 },
            { name = "Fusil compact",        hash = "WEAPON_COMPACTRIFLE",       ammo = 600 }
        }
    },
    {
        name = "Mitrailleuses",
        icon = "🔫",
        weapons = {
            { name = "MG",                 hash = "WEAPON_MG",           ammo = 800 },
            { name = "MG de combat",       hash = "WEAPON_COMBATMG",     ammo = 800 },
            { name = "MG de combat Mk II", hash = "WEAPON_COMBATMG_MK2", ammo = 800 },
            { name = "Gusenberg",          hash = "WEAPON_GUSENBERG",    ammo = 800 }
        }
    },
    {
        name = "Fusils de sniper",
        icon = "🎯",
        weapons = {
            { name = "Fusil de sniper",          hash = "WEAPON_SNIPERRIFLE",       ammo = 100 },
            { name = "Fusil lourd",              hash = "WEAPON_HEAVYSNIPER",       ammo = 100 },
            { name = "Fusil lourd Mk II",        hash = "WEAPON_HEAVYSNIPER_MK2",   ammo = 100 },
            { name = "Fusil de précision",       hash = "WEAPON_MARKSMANRIFLE",     ammo = 100 },
            { name = "Fusil de précision Mk II", hash = "WEAPON_MARKSMANRIFLE_MK2", ammo = 100 }
        }
    },
    {
        name = "Fusils à pompe",
        icon = "🔫",
        weapons = {
            { name = "Fusil à pompe",       hash = "WEAPON_PUMPSHOTGUN",     ammo = 300 },
            { name = "Fusil à pompe Mk II", hash = "WEAPON_PUMPSHOTGUN_MK2", ammo = 300 },
            { name = "Fusil sawed-off",     hash = "WEAPON_SAWNOFFSHOTGUN",  ammo = 300 },
            { name = "Fusil d'assaut",      hash = "WEAPON_ASSAULTSHOTGUN",  ammo = 300 },
            { name = "Fusil bullpup",       hash = "WEAPON_BULLPUPSHOTGUN",  ammo = 300 },
            { name = "Musket",              hash = "WEAPON_MUSKET",          ammo = 300 },
            { name = "Fusil lourd",         hash = "WEAPON_HEAVYSHOTGUN",    ammo = 300 },
            { name = "Double canon",        hash = "WEAPON_DBSHOTGUN",       ammo = 300 },
            { name = "Fusil automatique",   hash = "WEAPON_AUTOSHOTGUN",     ammo = 300 }
        }
    },
    {
        name = "Armes lourdes",
        icon = "💥",
        weapons = {
            { name = "Lance-grenades",   hash = "WEAPON_GRENADELAUNCHER", ammo = 50 },
            { name = "RPG",              hash = "WEAPON_RPG",             ammo = 20 },
            { name = "Minigun",          hash = "WEAPON_MINIGUN",         ammo = 1000 },
            { name = "Lance-feux",       hash = "WEAPON_FLAREGUN",        ammo = 100 },
            { name = "Homing Launcher",  hash = "WEAPON_HOMINGLAUNCHER",  ammo = 20 },
            { name = "Compact Launcher", hash = "WEAPON_COMPACTLAUNCHER", ammo = 50 },
            { name = "Railgun",          hash = "WEAPON_RAILGUN",         ammo = 50 }
        }
    },
    {
        name = "Explosifs",
        icon = "💣",
        weapons = {
            { name = "Grenade",             hash = "WEAPON_GRENADE",      ammo = 25 },
            { name = "Grenade BZ",          hash = "WEAPON_BZGAS",        ammo = 25 },
            { name = "Grenade fumigène",    hash = "WEAPON_SMOKEGRENADE", ammo = 25 },
            { name = "Grenade lacrymogène", hash = "WEAPON_BZGAS",        ammo = 25 },
            { name = "Cocktail Molotov",    hash = "WEAPON_MOLOTOV",      ammo = 25 },
            { name = "Mine de proximité",   hash = "WEAPON_PROXMINE",     ammo = 5 },
            { name = "Bombe collante",      hash = "WEAPON_STICKYBOMB",   ammo = 25 },
            { name = "Bombe à fragment",    hash = "WEAPON_PIPEBOMB",     ammo = 10 }
        }
    }
}

function ShowWeaponCategories(targetId, targetName)
    local menuTitle = targetId and ('Armes pour ' .. targetName) or 'Mes armes'
    local weaponCategoryMenu = MenuV:CreateMenu(menuTitle, false, 'topright', 255, 0, 0, "size-125", 'interaction_bgd',
        'commonmenu',
        false, 'native')

    if not targetId then
        local playerId = PlayerId()
        local playerServerId = GetPlayerServerId(playerId)
        local playerName = GetPlayerName(playerId)

        targetId = playerServerId
        targetName = playerName
    end

    for _, category in ipairs(WeaponCategories) do
        weaponCategoryMenu:AddButton({
            icon = category.icon,
            label = category.name,
            description = 'Voir les armes de type ' .. category.name,
            select = function()
                ShowWeaponsInCategory(targetId, targetName, category)
            end
        })
    end

    weaponCategoryMenu:Open()
end

function ShowWeaponsInCategory(targetId, targetName, category)
    local menuTitle = targetId and (category.name .. ' pour ' .. targetName) or category.name
    local weaponMenu = MenuV:CreateMenu(menuTitle, false, 'topright', 255, 0, 0, "size-125", 'interaction_bgd',
        'commonmenu',
        false, 'native')

    for _, weapon in ipairs(category.weapons) do
        local currentPlayerId = GetPlayerServerId(PlayerId())
        local isSelf = (targetId == currentPlayerId)

        local description = targetId and
            ('Donner ' .. weapon.name .. ' avec ' .. weapon.ammo .. ' munitions') or
            ('Prendre ' .. weapon.name .. ' avec ' .. weapon.ammo .. ' munitions')

        weaponMenu:AddButton({
            icon = '🔫',
            label = weapon.name,
            description = description,
            select = function()
                if isSelf then
                    local playerPed = PlayerPedId()
                    local weaponHash = GetHashKey(weapon.hash)

                    GiveWeaponToPed(playerPed, weaponHash, weapon.ammo, false, true)
                    TriggerServerEvent('r_admin:client:showNotification',
                        'Arme ' .. weapon.name .. ' reçue avec ' .. weapon.ammo .. ' munitions', "success")
                else
                    TriggerServerEvent('r_admin:giveWeaponToPlayer', targetId, weapon.hash, weapon.ammo)
                    TriggerServerEvent('r_admin:client:showNotification',
                        'Arme ' .. weapon.name .. ' donnée à ' .. targetName .. ' avec ' .. weapon.ammo .. ' munitions',
                        "success")
                end
            end
        })
    end

    weaponMenu:Open()
end
