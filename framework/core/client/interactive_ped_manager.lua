GlobalNPCs = {}

local npcInteractionDistance = 3.0
local currentNearestNPC = nil

local defaultNPCConfig = {
    invincible = true,
    freeze = true,
    blockEvents = true,
    scenario = "WORLD_HUMAN_STAND_IMPATIENT",
    useRandomVariation = true,
    networkMission = true,
    pedType = 4
}

-- Créé un pnj intéractif
function CreateInteractiveNPC(config)
    if not config or not config.model or not config.coords then
        print("CreateInteractiveNPC: Modèle et coordonnées requis")
        return nil
    end

    local npcConfig = {}

    -- Overwrite la config de base
    for k, v in pairs(defaultNPCConfig) do
        npcConfig[k] = config[k] ~= nil and config[k] or v
    end

    for k, v in pairs(config) do
        npcConfig[k] = v
    end

    local pedHash = GetHashKey(npcConfig.model)

    RequestModel(pedHash)
    local timeout = 0
    while not HasModelLoaded(pedHash) and timeout < 1000 do
        Citizen.Wait(1)
        timeout = timeout + 1
    end

    if not HasModelLoaded(pedHash) then
        print(string.format("Impossible de charger le modèle %s", npcConfig.model))
        return nil
    end

    local coords = npcConfig.coords
    local heading = npcConfig.heading or 0.0
    local ped = CreatePed(npcConfig.pedType, pedHash, coords.x, coords.y, coords.z - 1.0, heading,
        npcConfig.networkMission, true)

    if not DoesEntityExist(ped) then
        print("Echec de la création du pnj")
        SetModelAsNoLongerNeeded(pedHash)
        return nil
    end

    SetEntityCanBeDamaged(ped, not npcConfig.invincible)
    SetPedCanRagdollFromPlayerImpact(ped, not npcConfig.invincible)
    SetBlockingOfNonTemporaryEvents(ped, npcConfig.blockEvents)
    SetEntityInvincible(ped, npcConfig.invincible)

    if npcConfig.freeze then
        FreezeEntityPosition(ped, true)
    end

    if npcConfig.scenario then
        TaskStartScenarioInPlace(ped, npcConfig.scenario, 0, true)
    end

    if npcConfig.useRandomVariation then
        SetPedRandomComponentVariation(ped, true)
    end

    SetModelAsNoLongerNeeded(pedHash)

    local npcId = #GlobalNPCs + 1

    GlobalNPCs[npcId] = {
        ped = ped,
        config = npcConfig,
        id = npcId
    }

    print(string.format("pnj créé (id: %d, Modèle: %s)", npcId, npcConfig.model))
    return npcId
end

-- Créé plusieurs pnj à partir d'un tableau de config
function CreateMultipleNPC(configs)
    local npcIds = {}

    if not configs or type(configs) ~= "table" then
        print("CreateMultipleNPC: Tableau de configuration requis")
        return npcIds
    end

    for i, config in pairs(configs) do
        local npcId = CreateInteractiveNPC(config)
        if npcId then
            table.insert(npcIds, npcId)
        end
    end

    print(string.format("%d pnj créés sur %d configurations", #npcIds, #configs))
    return npcIds
end

-- Supprime un pnj grâce à son id
function DeleteNPC(npcId)
    if not GlobalNPCs[npcId] then
        print(string.format("pnj avec l'id %d introuvable", npcId))
        return false
    end

    local npcData = GlobalNPCs[npcId]
    if DoesEntityExist(npcData.ped) then
        DeleteEntity(npcData.ped)
    end

    GlobalNPCs[npcId] = nil
    print(string.format("pnj supprimé (id: %d)", npcId))
    return true
end

-- Supprime tous les pnj
function DeleteAllNPC()
    local count = 0
    for npcId, npcData in pairs(GlobalNPCs) do
        if DoesEntityExist(npcData.ped) then
            DeleteEntity(npcData.ped)
            count = count + 1
        end
    end

    GlobalNPCs = {}
    print(string.format("%d pnj supprimés", count))
end

-- Obtient les données d'un pnj grâce à son id
function GetNPCData(npcId)
    return GlobalNPCs[npcId]
end

-- Vérifie si un joueur est proche d'un pnj
function IsNearNPC(coords, npcId, distance)
    local npcData = GlobalNPCs[npcId]
    if not npcData or not DoesEntityExist(npcData.ped) then
        return false
    end

    local npcCoords = GetEntityCoords(npcData.ped)
    local dist = distance or npcInteractionDistance
    return #(coords - npcCoords) <= dist
end

function SetNPCInteractionDistance(distance)
    npcInteractionDistance = distance
end

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearestNPC = nil
        local nearestDistance = math.huge

        for npcId, npcData in pairs(GlobalNPCs) do
            if DoesEntityExist(npcData.ped) then
                local npcCoords = GetEntityCoords(npcData.ped)
                local distance = #(playerCoords - npcCoords)

                if distance <= npcInteractionDistance and distance < nearestDistance then
                    nearestDistance = distance
                    nearestNPC = npcData
                    sleep = 200
                end
            end
        end

        currentNearestNPC = nearestNPC
        Citizen.Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000

        if currentNearestNPC then
            sleep = 0
            local config = currentNearestNPC.config
            local message = config.interactionText or "Appuyez sur E pour intéragir"

            ShowProximityNotification(message)

            if IsControlJustPressed(0, 38) then
                if config.onInteract then
                    if type(config.onInteract) == "function" then
                        config.onInteract(currentNearestNPC.id, currentNearestNPC)
                    end
                end
            end
        else
            HideProximityNotification()
        end

        Citizen.Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DeleteAllNPC()
    end
end)
