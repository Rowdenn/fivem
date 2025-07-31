local isDead = false
local isInDeathState = false
local isInDeathProcess = false
local lastWeaponHash = nil
local deathTimer = 0
local uiOpen = false

local weaponCat = {
    ["unarmed"] = GetHashKey("WEAPON_UNARMED"),
    ["knife"] = GetHashKey("WEAPON_KNIFE"),
    ["gun"] = {
        GetHashKey("WEAPON_PISTOL"),
        GetHashKey("WEAPON_COMBATPISTOL"),
        GetHashKey("WEAPON_APPISTOL"),
        GetHashKey("WEAPON_SMG"),
        GetHashKey("WEAPON_ASSAULTRIFLE"),
        GetHashKey("WEAPON_CARBINERIFLE"),
        GetHashKey("WEAPON_ASSAULTSHOTGUN"),
        GetHashKey("WEAPON_SNIPERRIFLE")
    }
}

local comaTimers = {
    ["unarmed"] = 15, -- 15 seconds for unarmed
    ["knife"] = 45,   -- 45 seconds for knife
    ["gun"] = 60,     -- 60 seconds for gun
    ["hunger"] = 40,  -- 40 seconds for hunger
    ["thirst"] = 40,  -- 40 seconds for thirst
    ["unknown"] = 30  -- 30 seconds for unknown causes
}

function DisableAllControls()
    DisableAllControlActions(0)
    DisableAllControlActions(2)

    EnableControlAction(0, 245, true) -- Chat
end

function HandlePlayerDeath()
    isInDeathState = true
    isDead = true

    if not isInDeathProcess then
        DetectDeathCause()
    end
end

function GetWeaponCategory(weaponHash)
    if weaponHash == weaponCat["unarmed"] then
        return "unarmed"
    end

    if weaponHash == weaponCat["knife"] then
        return "knife"
    end

    for _, gunHash in ipairs(weaponCat["gun"]) do
        if weaponHash == gunHash then
            return "gun"
        end
    end

    return "unknown"
end

function ResetDeathState()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)

    ClearPedTasks(player)
    ClearPedTasksImmediately(player)

    SetEntityCoords(player, coords.x, coords.y, coords.z, false, false, false, true)

    SetEntityHealth(player, 150)

    isDead = false
    isInDeathState = false
    isInDeathProcess = false
    deathTimer = 0

    ClearPedBloodDamage(player)
    ClearPedWetness(player)
    ClearPedEnvDirt(player)
    ClearPedDamageDecalByZone(player, 0, "ALL")

    EnableAllControlActions(0)
    SetPlayerControl(PlayerId(), true, 0)

    HideComaInterface()
    MakePlayerInvisibleToNPCs(false)
end

function ShowComaInterface(cat, koTime)
    if not uiOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = "showDeath",
            cat = cat,
            koTime = koTime
        })
        uiOpen = true
    end
end

function HideComaInterface()
    if uiOpen then
        SendNUIMessage({
            action = "hideDeath"
        })
        uiOpen = false
    end
end

function UpdateComaInterface(timeLeft)
    if uiOpen then
        SendNUIMessage({
            action = "updateTimer",
            timeLeft = timeLeft
        })
    end
end

function StartDeathProcess(cat, koTime)
    if isInDeathProcess then return end

    isInDeathProcess = true
    deathTimer = koTime

    exports['framework']:SetForcedRagdoll(true)
    MakePlayerInvisibleToNPCs(true)

    ShowComaInterface(cat, koTime)
    StartDeathTimer()
end

function DetectDeathCause()
    if isInDeathProcess then
        return
    end

    local cat = "unknown"

    if lastWeaponHash then
        cat = GetWeaponCategory(lastWeaponHash)
    end

    local koTime = comaTimers[cat]

    StartDeathProcess(cat, koTime)
end

function StartDeathTimer()
    Citizen.CreateThread(function()
        while deathTimer > 0 and isInDeathProcess do
            Citizen.Wait(1000)
            deathTimer = deathTimer - 1
            UpdateComaInterface(deathTimer)
        end

        -- Quand le timer arrive à 0, on reset automatiquement l'état de mort
        if deathTimer <= 0 and isInDeathProcess then
            ResetDeathState()
        end
    end)
end

function MakePlayerInvisibleToNPCs(enable)
    if enable then
        SetEveryoneIgnorePlayer(PlayerId(), true)
        SetPoliceIgnorePlayer(PlayerId(), true)
    else
        print("Restoring player visibility to NPCs")
        SetEveryoneIgnorePlayer(PlayerId(), false)
        SetPoliceIgnorePlayer(PlayerId(), false)
    end
end

RegisterCommand('testdeath', function(source, args)
    if args[1] then
        local cat = args[1]
        local weapon = GetWeaponCategory(GetHashKey("WEAPON_" .. string.upper(cat)))
        local koTime = comaTimers[cat] or 30
        StartDeathProcess(weapon, koTime)
    else
        print("Usage: /testdeath <category>")
    end
end, false)

-- Commande pour forcer la récupération (optionnelle, pour les admins par exemple)
RegisterCommand("revive", function()
    if isInDeathProcess then
        ResetDeathState()
    end
end, false)

-- Désactive l'auto-spawn du spawnmanager
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    exports.spawnmanager:setAutoSpawn(false)
end)

-- Vérifie si le joueur est mort toutes les 100ms
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)

        local player = PlayerPedId()
        local health = GetEntityHealth(player)

        if health <= 0 and not isDead and not isInDeathProcess and not isInDeathState then
            HandlePlayerDeath()
        end

        if isInDeathState then
            if isInDeathState and health > 0 and not isInDeathProcess then
                isInDeathState = false
                isDead = false
            end
        end
    end
end)

-- Désactive les contrôles si le joueur est en état de coma
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if isInDeathProcess then
            DisableAllControls()
        end
    end
end)

-- Ecoute l'event CEventNetworkEntityDamage pour récupérer les infos des sources de dégâts
AddEventHandler('gameEventTriggered', function(name, data)
    if name == "CEventNetworkEntityDamage" then
        local player = PlayerPedId()
        local victim = data[1]
        local attacker = data[2]
        local weaponHash = data[5]

        if victim == player then
            lastWeaponHash = weaponHash

            if attacker ~= 0 then
                if IsPedAPlayer(attacker) then
                    local attackerId = NetworkGetPlayerIndexFromPed(attacker)
                    local attackerName = GetPlayerName(attackerId)
                    -- TODO Ajouter les logs discord
                end
            end

            print("Player damaged by: " .. GetWeaponCategory(weaponHash))
        end
    end
end)

exports('StartDeathProcess', function(cat, koTime)
    if not isInDeathProcess then
        StartDeathProcess(cat, koTime)
    end
end)
