function ShowNotificationToPlayer(playerId, data)
    TriggerClientEvent('r_notify:showNotification', playerId, data)
end

function ShowNotificationToAll(data)
    TriggerClientEvent('r_notify:showNotification', -1, data)
end

RegisterServerEvent('r_notify:server:showNotification')
AddEventHandler('r_notify:server:showNotification', function(data)
    local source = source
    ShowNotificationToPlayer(source, data)
end)

RegisterServerEvent('r_notify:server:showNotificationToAll')
AddEventHandler('r_notify:server:showNotificationToAll', function(data)
    local source = source
    -- TODO Ajouter une vérification (si joueur admin, chef d'entreprise et certainement d'autres trucs)
    ShowNotificationToAll(data)
end)

function ShowProximityNotificationToPlayer(playerId, message)
    TriggerClientEvent('r_notify:showProximity', playerId, message)
end

function HideProximityNotificationToPlayer(playerId)
    TriggerClientEvent('r_notify:hideProximity', playerId)
end
