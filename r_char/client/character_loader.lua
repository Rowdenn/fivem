local loadedCharacter = nil
local loadedSex = nil
local firstSpawn = true

AddEventHandler('playerSpawned', function() 
    if firstSpawn then
        TriggerServerEvent('r_char:checkCharacter')
        firstSpawn = false
    end
end)

-- Événement pour charger un personnage existant
RegisterNetEvent('r_char:loadCharacter')
AddEventHandler('r_char:loadCharacter', function(character, sex, lastPosition)
    loadedCharacter = character
    loadedSex = sex
    
    LoadExistingCharacter(character, sex, lastPosition)
end)

-- Fonction dédiée au chargement des personnages existants
function LoadExistingCharacter(character, sex, lastPosition)
    local playerPed = PlayerPedId()
    local characterData
    
    -- Décoder les données selon le type reçu
    if type(character) == 'string' then
        characterData = json.decode(character)
        if not characterData then
            print('ERREUR: Impossible de décoder le JSON du personnage')
            return
        end
    elseif type(character) == 'table' then
        characterData = character
    else
        print('ERREUR: Type de données invalide pour le chargement:', type(character))
        return
    end
    
    -- Attendre que l'entité existe
    while not DoesEntityExist(playerPed) do
        Citizen.Wait(10)
        playerPed = PlayerPedId()
    end
    
    -- Charger le modèle approprié
    local requiredModel = DetermineModelBySex(sex)
    if not LoadPlayerModel(requiredModel, false) then
        print('ERREUR: Impossible de charger le modèle pour le chargement')
        return
    end
    
    -- Attendre que le modèle soit appliqué
    Citizen.Wait(1000)
    playerPed = PlayerPedId()
    
    -- Appliquer l'apparence
    ApplyLoadedCharacterAppearance(playerPed, characterData, sex)
    
    -- Téléporter le joueur
    local spawnCoords = vector3(lastPosition.x, lastPosition.y, lastPosition.z)
    SetEntityCoords(playerPed, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, true)
end

-- Fonction dédiée à l'application d'apparence pour les personnages chargés
function ApplyLoadedCharacterAppearance(playerPed, characterData, sex)
    Citizen.Wait(100)
    
    -- Traits du visage
    for i = 0, 19 do
        local featureKey = "face_feature_" .. i
        if characterData[featureKey] then
            SetPedFaceFeature(playerPed, i, characterData[featureKey])
        end
    end
    
    -- Cheveux
    SetPedComponentVariation(playerPed, 2, characterData.hair or 0, 0, 0)
    SetPedHairTint(playerPed, characterData.hair_color or 0, characterData.hair_highlight or 0)
    
    -- Yeux
    SetPedEyeColor(playerPed, characterData.eye_color or 0)
    
    -- Barbe
    if sex == 0 then
        SetPedHeadOverlay(playerPed, 1, characterData.beard or 0, 1.0)
        SetPedHeadOverlayColor(playerPed, 1, 1, characterData.beard_color or 0, 0)
    end
    
    -- Sourcils
    SetPedHeadOverlay(playerPed, 2, characterData.eyebrows or 0, 1.0)
    SetPedHeadOverlayColor(playerPed, 2, 1, characterData.eyebrows_color or 0, 0)
    
    -- Vêtements
    SetPedComponentVariation(playerPed, 11, characterData.torso or 0, characterData.torso_texture or 0, 0)
    SetPedComponentVariation(playerPed, 4, characterData.legs or 0, characterData.legs_texture or 0, 0)
    SetPedComponentVariation(playerPed, 6, characterData.shoes or 0, characterData.shoes_texture or 0, 0)
end

-- Fonction pour reload l'apparence
function ReloadCharacterAppearance()
    if loadedCharacter and loadedSex then
        LoadExistingCharacter(loadedCharacter, loadedSex)
    end
end

-- Commande de debug
RegisterCommand('reloadchar', function()
    ReloadCharacterAppearance()
end, false)
