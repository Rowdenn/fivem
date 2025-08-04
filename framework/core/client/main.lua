-- Valeurs en pourcentage
local trafficAmount = 50
local pedestrianAmount = 50
local parkedAmount = 50
local enableDispatch = false
local enableBoats = false
local enableTrains = false
local enableGarbageTrucks = false

local vehicleModels = {
    "ambulance", "firetruk", "polmav", "police", "police2", "police3", "police4", "fbi", "fbi2", "policet", "policeb",
    "riot", "apc", "barracks", "barracks2", "barracks3", "rhino", "hydra", "lazer", "valkyrie",
    "valkyrie2", "savage", "trailersmall2", "barrage", "chernobog", "khanjali", "menacer", "scarab", "scarab2", "scarab3",
    "armytanker", "avenger", "avenger2", "tula", "bombushka", "molotok", "volatol", "starling",
    "mogul", "nokota", "strikeforce", "rogue", "cargoplane", "jet", "buzzard", "besra", "titan", "cargobob", "cargobob2",
    "cargobob3", "cargobob4", "akula", "hunt"
}

local pedModels = {
    "s_m_m_paramedic_01", "s_m_m_paramedic_02", "s_m_y_fireman_01", "s_m_y_pilot_01", "s_m_y_cop_01", "s_m_y_cop_02",
    "s_m_y_swat_01", "s_m_y_hwaycop_01", "s_m_y_marine_01", "s_m_y_marine_02", "s_m_y_marine_03",
    "s_m_m_marine_01", "s_m_m_marine_02"
}

function DisableWantedSystem()
    -- Supprime les flics de con
    SetMaxWantedLevel(0)
    SetPoliceIgnorePlayer(PlayerId(), true)
    SetPoliceRadarBlips(false)
end

-- TODO : Revoir le système pour gérer les véhicules des dispatch (supprime également les véhicules des joueurs)
Citizen.CreateThread(function()
    for _, modelName in ipairs(vehicleModels) do
        SetVehicleModelIsSuppressed(GetHashKey(modelName), true)
    end

    for _, modelName in ipairs(pedModels) do
        SetPedModelIsSuppressed(GetHashKey(modelName), true)
    end

    for i = 1, 13 do
        EnableDispatchService(i, enableDispatch)
    end

    while true do
        Citizen.Wait(1000)

        local player = GetPlayerPed(-1)
        local playerCoords = GetEntityCoords(player)
        ClearAreaOfCops(playerCoords.x, playerCoords.y, playerCoords.z, 400.0, true)

        local vehicles = GetGamePool('CVehicle')
        for i = 1, #vehicles do
            local vehicle = vehicles[i]
            local model = GetEntityModel(vehicle)

            for _, modelName in ipairs(vehicleModels) do
                if model == GetHashKey(modelName) then
                    SetEntityAsMissionEntity(vehicle, true, true)
                    DeleteVehicle(vehicle)
                    break
                end
            end
        end

        local peds = GetGamePool('CPed')
        for i = 1, #peds do
            local ped = peds[i]
            local model = GetEntityModel(ped)

            for _, modelName in ipairs(pedModels) do
                if model == GetHashKey(modelName) then
                    SetEntityAsMissionEntity(ped, true, true)
                    DeleteVehicle(ped)
                    break
                end
            end
        end

        SetVehicleDensityMultiplierThisFrame((trafficAmount / 100) + .0)
        SetPedDensityMultiplierThisFrame((pedestrianAmount / 100) + .0)
        SetRandomVehicleDensityMultiplierThisFrame((trafficAmount / 100) + .0)
        SetParkedVehicleDensityMultiplierThisFrame((parkedAmount / 100) + .0)
        SetScenarioPedDensityMultiplierThisFrame((pedestrianAmount / 100) + .0, (pedestrianAmount / 100) + .0)
        SetRandomBoats(enableBoats)
        SetRandomTrains(enableTrains)
        SetGarbageTrucks(enableGarbageTrucks)
        SetScenarioTypeEnabled("DRIVE", true)
        SetScenarioTypeEnabled("WALK", true)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerId = PlayerId()

        if GetPlayerWantedLevel(playerId) > 0 then
            SetPlayerWantedLevel(playerId, 0, false)
            SetPlayerWantedLevelNow(playerId, false)
        end

        SetPlayerWantedLevelNoDrop(playerId, 0, false)
    end
end)

AddEventHandler('onClientResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end

    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(0)
    end

    DisableWantedSystem()
end)

local isPlayerRagdoll = false
local isRagdollForced = false

-- Fonction export pour forcer le ragdoll dans d'autres scripts
function SetForcedRagdoll(state)
    isRagdollForced = state
    if state then
        isPlayerRagdoll = false
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local player = PlayerPedId()

        -- Si le ragdoll est forcé par un autre script
        if isRagdollForced then
            if not IsPedRagdoll(player) then
                SetPedToRagdoll(player, 1000, 1000, 0, false, false, false)
            end

            if IsControlJustPressed(0, 73) then -- touche X
                isRagdollForced = false
                isPlayerRagdoll = false
                ExitRagdoll(player)
            end
            -- Si le ragdoll est voulu par le joueur
        elseif isPlayerRagdoll then
            if not IsPedRagdoll(player) then
                SetPedToRagdoll(player, 1000, 1000, 0, false, false, false)
            end

            if IsControlJustPressed(0, 73) then -- touche X
                isPlayerRagdoll = false
                ExitRagdoll(player)
            end
            -- Aucun ragdoll d'actif
        else
            if IsControlJustPressed(0, 73) then -- touche X
                isPlayerRagdoll = true
                SetPedToRagdoll(player, 1000, 1000, 0, false, false, false)
            end
        end
    end
end)

-- Permet de sortir de l'état de ragdoll
function ExitRagdoll(ped)
    TaskPlayAnim(ped, "get_up@directional@transition@prone_to_seated@crawl", "front", 8.0, -8.0, 1000, 0, 0, false, false,
        false)
end

function StartForcedRagdoll()
    isRagdollForced = true
    isPlayerRagdoll = false
end

function StopForcedRagdoll()
    isRagdollForced = false
    isPlayerRagdoll = false
    local player = PlayerPedId()
    ExitRagdoll(player)
end

function IsPlayerInRagdoll()
    return isPlayerRagdoll or isRagdollForced
end

function IsPlayerVoluntaryRagdoll()
    return isPlayerRagdoll
end

function IsPlayerForceRagdoll()
    return isRagdollForced
end

function RegisterAndHandleNetEvent(event, cb)
    RegisterNetEvent(event)
    AddEventHandler(event, cb)
end
