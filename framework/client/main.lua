-- Ajouter ceci au début du fichier
local PlayerLoaded = false

-- Événement de connexion
AddEventHandler('playerSpawned', function()
    if not PlayerLoaded then
        -- Demander la vérification du personnage
        TriggerServerEvent('framework:server:CheckCharacterExists')
    end
end)

-- Événement de joueur chargé
RegisterNetEvent('framework:client:PlayerLoaded')
AddEventHandler('framework:client:PlayerLoaded', function(PlayerData)
    Framework.PlayerData = PlayerData
    PlayerLoaded = true
    
    -- Déclencher les événements de démarrage
    TriggerEvent('framework:client:OnPlayerLoaded')
    
    -- Charger la position
    if PlayerData.position and PlayerData.position.x then
        SetEntityCoords(PlayerPedId(), PlayerData.position.x, PlayerData.position.y, PlayerData.position.z)
        SetEntityHeading(PlayerPedId(), PlayerData.position.heading or 0.0)
    end
end)
