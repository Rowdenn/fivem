local creatorCharacter = {
    sex = 0,
    hair = 0,
    hair_color = 0,
    hair_highlight = 0,
    face_shape = 0,
    skin_tone = 0,

    -- overlays
    beard = 0,
    beard_color = 0,
    eyebrows = 0,
    eyebrows_color = 0,
    blemishes = 0,
    blemishes_opacity = 50,
    ageing = 0,
    makeup = 0,
    makeup_opacity = 0,
    blush = 0,
    blush_color = 0,
    complexion = 0,
    sun_damage = 0,
    lipstick = 0,
    lipstick_color = 0,
    freckles = 0,
    ches_hair = 0,
    chest_hair_color = 0,
    moles = 0,
    body_blemishes = 0,

    mask = 0,
    mask_texture = 0,
    bag = 0,
    bag_texture = 0,
    accessory = 0,
    accessory_texture = 0,
    undershirt = 0,
    undershirt_texture = 0,
    kevlar = 0,
    kevlar_texture = 0,
    badge = 0,
    badge_texture = 0,
    torso2 = 0,
    torso2_texture = 0,
    eye_color = 0,
    torso = 0,
    torso_texture = 0,
    legs = 0,
    legs_texture = 0,
    shoes = 0,
    shoes_texture = 0
}

local creatorCamera = nil
local inCreator = false
local lastSexValue = nil

-- Variables du zoom de la cam
local cameraZoomLevel = 0.0                      -- 0.0 position initiale, 1.0 zoom max sur le visage
local baseCameraOffset = vector3(0.0, 4.0, 0.5)  -- Position de base de la caméra
local zoomCameraOffset = vector3(0.0, -4.5, 1.5) -- Position du zoom
local maxZoomLevel = 0.3
local minZoomLevel = 0.0
local zoomStep = 0.05

-- Rotation du perso
local isRotating = false
local targetRotation = 0
local currentRotation = 0
local rotationSpeed = 6.0
local rotationStep = 90.0
local baseHeading = 180.0

function RotatePlayer(direction)
    if not inCreator then return end

    local playerPed = PlayerPedId()
    if not DoesEntityExist(playerPed) then return end

    if direction == "left" then
        targetRotation = (currentRotation - rotationStep) % 360
    elseif direction == "right" then
        targetRotation = (currentRotation + rotationStep) % 360
    elseif direction == "front" then
        targetRotation = 0.0
    elseif direction == "back" then
        targetRotation = 180.0
    end

    isRotating = true

    Citizen.CreateThread(function()
        while isRotating do
            local diff = targetRotation - currentRotation

            if diff > 180 then
                diff = diff - 360
            elseif diff < -180 then
                diff = diff + 360
            end

            if math.abs(diff) > rotationSpeed then
                currentRotation = currentRotation + (diff > 0 and rotationSpeed or -rotationSpeed)
            else
                currentRotation = targetRotation
                isRotating = false
            end

            currentRotation = currentRotation % 360

            local newHeading = baseHeading + currentRotation
            SetEntityHeading(playerPed, newHeading)

            Citizen.Wait(16)
        end
    end)
end

-- Interpole entre deux vecteurs
function LerpVector3(a, b, t)
    return vector3(
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
        a.z + (b.z - a.z) * t
    )
end

-- Crée la cam
function CreateCreatorCamera(playerPed)
    if creatorCamera then
        DestroyCam(creatorCamera, false)
    end

    creatorCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    UpdateCameraZoom(cameraZoomLevel, playerPed)
    SetCamActive(creatorCamera, true)
    RenderScriptCams(true, false, 0, true, true)

    return creatorCamera
end

-- Met à jour le zoom de la cam
function UpdateCameraZoom(zoomLevel, playerPed)
    if not creatorCamera or not DoesEntityExist(playerPed) then return end

    zoomLevel = math.max(minZoomLevel, math.min(maxZoomLevel, zoomLevel))
    cameraZoomLevel = zoomLevel

    local targetOffset = LerpVector3(baseCameraOffset, zoomCameraOffset, zoomLevel)
    local pedCoords = GetEntityCoords(playerPed)

    local radians = math.rad(baseHeading)
    local forwardX = math.sin(radians) * targetOffset.y
    local forwardY = math.cos(radians) * targetOffset.y

    local cameraCoords = vector3(
        pedCoords.x + forwardX + targetOffset.x,
        pedCoords.y + forwardY + 0.3,
        pedCoords.z + targetOffset.z
    )

    local baseTarget = vector3(pedCoords.x + 0.5, pedCoords.y, pedCoords.z + 0.5)
    local zoomTarget = vector3(pedCoords.x - 0.7, pedCoords.y, pedCoords.z + 1.0)
    local currentTarget = LerpVector3(baseTarget, zoomTarget, zoomLevel)

    SetCamCoord(creatorCamera, cameraCoords.x, cameraCoords.y, cameraCoords.z)
    PointCamAtCoord(creatorCamera, currentTarget.x, currentTarget.y, currentTarget.z)

    local fov = 50.0 - (zoomLevel * 20.0)
    SetCamFov(creatorCamera, fov)
end

-- Démarrer le créateur de personnage
function StartCharacterCreator()
    local playerPed = PlayerPedId()

    SetEntityCoords(playerPed, -75.448349, -819.151489, 326.175018, false, false, false, true)
    SetEntityHeading(playerPed, baseHeading)

    playerRotation = 0.0

    lastSexValue = 0
    creatorCharacter.sex = 0

    local defaultModel = "mp_m_freemode_01"
    if not LoadPlayerModel(defaultModel, true) then
        print('ERREUR: Impossible de charger le modèle par défaut')
        return
    end

    Citizen.CreateThread(function()
        Citizen.Wait(100)

        local newPed = PlayerPedId()

        -- Vérifie que le ped existe
        if not DoesEntityExist(newPed) then
            print('ERREUR: Ped non trouvé après chargement du modèle')
            return
        end

        -- Applique l'apparence par défaut
        ApplyCreatorCharacterAppearance(newPed, creatorCharacter)

        CreateCreatorCamera(newPed)

        -- Freeze le joueur
        FreezeEntityPosition(newPed, true)
        SetEntityInvincible(newPed, true)

        -- Ouvrir l'interface avec le nouveau système UI
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'loadUI',
            module = 'character',
            data = {
                type = 'openCreator',
                character = creatorCharacter
            }
        })

        inCreator = true
    end)
end

-- Fonction dédiée à l'application d'apparence dans le créateur
function ApplyCreatorCharacterAppearance(playerPed, characterData)
    local timeout = 0
    while not DoesEntityExist(playerPed) and timeout < 50 do
        Citizen.Wait(10)
        playerPed = PlayerPedId()
        timeout = timeout + 1
    end

    if not DoesEntityExist(playerPed) then
        print('Ped non trouvé pour appliquer l\'apparence')
        return
    end

    local faceShape = characterData.face_shape or 0
    local skinTone = characterData.skin_tone or 0
    SetPedHeadBlendData(playerPed, faceShape, faceShape, 0, skinTone, skinTone, 0, 0.0, 0.0, 0.0, false)

    Citizen.Wait(50)

    -- Traits du visage
    for i = 0, 19 do
        local featureKey = "face_feature_" .. i
        if characterData[featureKey] then
            SetPedFaceFeature(playerPed, i, characterData[featureKey])
        end
    end

    -- Overlays
    -- Imperfections
    local blemishes = characterData.blemishes or 0
    if blemishes > 0 then
        SetPedHeadOverlay(playerPed, 0, blemishes, 1.0)
    else
        SetPedHeadOverlay(playerPed, 0, 255, 0.0)
    end

    -- Barbe
    if characterData.sex == 0 then
        local beard = characterData.beard or 0
        if beard > 0 then
            SetPedHeadOverlay(playerPed, 1, beard, 1.0)
            SetPedHeadOverlayColor(playerPed, 1, 1, characterData.beard_color or 0, 0)
        end
    else
        -- Retire la barbe pour les femmes
        SetPedHeadOverlay(playerPed, 1, 255, 0.0)
    end

    -- Sourcils
    if characterData.eyebrows > 0 then
        SetPedHeadOverlay(playerPed, 2, characterData.eyebrows, 1.0)
        SetPedHeadOverlayColor(playerPed, 2, 1, characterData.eyebrows_color or 0, 0)
    else
        SetPedHeadOverlay(playerPed, 2, 255, 0.0)
    end

    -- Vieillissement
    local ageing = characterData.ageing or 0
    if ageing > 0 then
        SetPedHeadOverlay(playerPed, 3, characterData.ageing, 1.0)
    else
        SetPedHeadOverlay(playerPed, 3, 255, 0.0)
    end

    -- Maquillage
    local makeup = characterData.makeup or 0
    if makeup > 0 then
        SetPedHeadOverlay(playerPed, 4, makeup, 1.0)
        SetPedHeadOverlayColor(playerPed, 4, 2, characterData.makeup_color or 0, 0)
    else
        SetPedHeadOverlay(playerPed, 4, 255, 0.0)
    end

    -- Blush
    local blush = characterData.blush or 0
    if blush > 0 then
        SetPedHeadOverlay(playerPed, 5, blush, 1.0)
        SetPedHeadOverlayColor(playerPed, 5, 2, characterData.blush_color or 0, 0)
    else
        SetPedHeadOverlay(playerPed, 5, 255, 0.0)
    end

    -- Complexités
    local complexion = characterData.complexion or 0
    if complexion > 0 then
        SetPedHeadOverlay(playerPed, 6, complexion, 1.0)
    else
        SetPedHeadOverlay(playerPed, 6, 255, 0.0)
    end

    -- Dégats du soleil
    local sun_damage = characterData.sun_damage or 0
    if sun_damage > 0 then
        SetPedHeadOverlay(playerPed, 7, sun_damage, 1.0)
    else
        SetPedHeadOverlay(playerPed, 7, 255, 0.0)
    end

    -- Rouge à lèvres
    local lipstick = characterData.lipstick or 0
    if lipstick > 0 then
        SetPedHeadOverlay(playerPed, 8, lipstick, 1.0)
        SetPedHeadOverlayColor(playerPed, 8, 2, characterData.lipstick_color or 0, 0)
    else
        SetPedHeadOverlay(playerPed, 8, 255, 0.0)
    end

    -- Tâches de rousseur
    local freckles = characterData.freckles or 0
    if freckles > 0 then
        SetPedHeadOverlay(playerPed, 9, freckles, 1.0)
    else
        SetPedHeadOverlay(playerPed, 9, 255, 0.0)
    end

    -- Poils du torse
    local chest_hair = characterData.chest_hair or 0
    if characterData.sex == 0 and chest_hair > 0 then
        SetPedHeadOverlay(playerPed, 10, chest_hair, 1.0)
        SetPedHeadOverlayColor(playerPed, 10, 1, characterData.chest_hair_color or 0, 0)
    else
        SetPedHeadOverlay(playerPed, 10, 255, 0.0)
    end

    -- Grain de beauté
    local moles = characterData.moles or 0
    if moles > 0 then
        SetPedHeadOverlay(playerPed, 11, moles, 1.0)
    else
        SetPedHeadOverlay(playerPed, 11, 255, 0.0)
    end

    -- Poils du corps
    local body_blemishes = characterData.body_blemishes or 0
    if characterData.sex == 0 and body_blemishes > 0 then
        SetPedHeadOverlay(playerPed, 12, body_blemishes, 1.0)
        SetPedHeadOverlayColor(playerPed, 12, 1, characterData.body_blemishes or 0, 0)
    else
        SetPedHeadOverlay(playerPed, 12, 255, 0.0)
    end

    -- Cheveux
    if characterData.hair then
        SetPedComponentVariation(playerPed, 2, characterData.hair, 0, 0)
    end

    if characterData.hair_color then
        SetPedHairTint(playerPed, characterData.hair_color, characterData.hair_highlight or 0)
    end

    -- Yeux
    if characterData.eye_color then
        SetPedEyeColor(playerPed, characterData.eye_color)
    end

    -- Vêtements

    -- Masque
    if characterData.mask then
        SetPedComponentVariation(playerPed, 1, characterData.mask, characterData.mask_texture or 0, 0)
    end

    -- Visage
    if characterData.face then
        SetPedComponentVariation(playerPed, 0, characterData.face, characterData.face_texture or 0, 0)
    end

    -- Texture des bras
    if characterData.torso then
        SetPedComponentVariation(playerPed, 3, characterData.torso, characterData.torso_texture or 0, 0)
    end

    -- Jambes
    if characterData.legs then
        SetPedComponentVariation(playerPed, 4, characterData.legs, characterData.legs_texture or 0, 0)
    end

    -- Sacs
    if characterData.bag then
        SetPedComponentVariation(playerPed, 5, characterData.bag, characterData.bag_texture or 0, 0)
    end

    -- Chaussures
    if characterData.shoes then
        SetPedComponentVariation(playerPed, 6, characterData.shoes, characterData.shoes_texture or 0, 0)
    end

    -- Accessoires
    if characterData.accessory then
        SetPedComponentVariation(playerPed, 7, characterData.accessory, characterData.accessory_texture or 0, 0)
    end

    -- Sous-vêtements
    if characterData.undershirt then
        SetPedComponentVariation(playerPed, 8, characterData.undershirt, characterData.undershirt_texture or 0, 0)
    end

    -- Kevlar
    if characterData.kevlar then
        SetPedComponentVariation(playerPed, 9, characterData.kevlar, characterData.kevlar_texture or 0, 0)
    end

    -- Badges
    if characterData.badge then
        SetPedComponentVariation(playerPed, 10, characterData.badge, characterData.badge_texture or 0, 0)
    end

    -- Vêtements haut
    if characterData.torso2 then
        SetPedComponentVariation(playerPed, 11, characterData.torso2, characterData.torso2_texture or 0, 0)
    end
end

-- Event pour ouvrir le menu de création
RegisterNetEvent('r_char:needCreation')
AddEventHandler('r_char:needCreation', function()
    StartCharacterCreator()
end)

RegisterNetEvent('r_char:cancelCreation')
AddEventHandler('r_char:cancelCreation', function()
    CloseCharacterCreator()
end)

-- Nouveau callback pour le zoom
RegisterNUICallback('updateZoom', function(data, cb)
    local zoomLevel = data.zoom or 0.0
    local playerPed = PlayerPedId()

    if creatorCamera and DoesEntityExist(playerPed) then
        UpdateCameraZoom(zoomLevel, playerPed)
    end

    cb('ok')
end)

RegisterNUICallback('rotatePlayer', function(data, cb)
    local direction = data.direction

    if not inCreator then
        cb('error')
        return
    end

    RotatePlayer(direction)
    cb('ok')
end)

RegisterNUICallback('setPlayerRotation', function(data, cb)
    local rotation = data.rotation or 0.0

    if not inCreator then
        cb('error')
        return
    end

    local playerPed = PlayerPedId()
    if not DoesEntityExist(playerPed) then
        cb('error')
        return
    end

    playerRotation = rotation
    local newHeading = baseHeading + playerRotation
    SetEntityHeading(playerPed, newHeading)

    cb('ok')
end)

-- Callback pour la mise à jour du personnage dans le créateur
RegisterNUICallback('updateCharacter', function(data, cb)
    for key, value in pairs(data) do
        creatorCharacter[key] = value
    end

    local playerPed = PlayerPedId()
    local needsModelChange = false

    -- Vérifie si le sexe a changé
    if data.sex ~= nil and data.sex ~= lastSexValue then
        lastSexValue = data.sex
        needsModelChange = true
    end

    if needsModelChange then
        local requiredModel = data.sex == 0 and "mp_m_freemode_01" or "mp_f_freemode_01"

        if creatorCamera then
            DetachCam(creatorCamera)
            DestroyCam(creatorCamera, false)
            creatorCamera = nil
        end

        if LoadPlayerModel(requiredModel, true) then
            Citizen.Wait(300)
            playerPed = PlayerPedId()

            CreateCreatorCamera(playerPed)

            ApplyCreatorCharacterAppearance(playerPed, creatorCharacter)
        end
    else
        -- Pas de changement de modèle, juste appliquer l'apparence
        ApplyCreatorCharacterAppearance(playerPed, creatorCharacter)
    end

    cb('ok')
end)

-- Callback pour finaliser la création
RegisterNUICallback('finishCreation', function(data, cb)
    TriggerServerEvent('r_char:saveCharacter', data)
    CloseCharacterCreator()

    cb('ok')
end)

function CloseCharacterCreator()
    if creatorCamera then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(creatorCamera, false)
        creatorCamera = nil
    end

    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    SetEntityInvincible(playerPed, false)

    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeUI',
        module = 'character'
    })

    inCreator = false

    -- Téléporte le joueur à l'aéroport
    SetEntityCoords(playerPed, -1042.31, -2745.9, 21.35, true, true, true, false)
end

RegisterCommand('debugchar', function()
    local playerPed = PlayerPedId()
    print('Player Ped ID:', playerPed)
    print('Ped exists:', DoesEntityExist(playerPed))
    print('Ped model:', GetEntityModel(playerPed))
    print('Ped coords:', GetEntityCoords(playerPed))
    print('In creator:', inCreator)
    print('Camera zoom level: ', cameraZoomLevel)
    if creatorCamera then
        print('Camera exists:', DoesCamExist(creatorCamera))
        print('Camera active:', IsCamActive(creatorCamera))
    end
end, false)

RegisterCommand('resetcreator', function()
    if inCreator then
        CloseCharacterCreator()
        Citizen.Wait(1000)
        StartCharacterCreator()
    end
end, false)

RegisterCommand('creator', function()
    if not inCreator then
        StartCharacterCreator()
    end
end, false)
