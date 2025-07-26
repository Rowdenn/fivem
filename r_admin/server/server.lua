RegisterServerEvent('r_admin:kickPlayer')
AddEventHandler('r_admin:kickPlayer', function(target, reason)
    local admin = source

    -- TODO: Ajouter la logique de kick
    exports['r_notify']:ShowNotificationToPlayer({
        message = "Joueur " .. target .. " kick avec succès",
        type = "success",
        duration = 5000
    })
end)

RegisterCommand('car', function(source, args)
    local player = source

    if not args[1] then
        TriggerClientEvent('chat:addMessage', player, {
            color = { 255, 0, 0 },
            muiltine = true,
            args = { 'Utilisation: /car <nom_du_vehicule)' }
        })
    end

    local vehicleName = args[1]:lower()

    TriggerClientEvent('r_admin:spawnVehicle', player, vehicleName)
end, false)

RegisterCommand('fix', function(source)
    local player = source
    TriggerClientEvent('r_admin:fixVehicle', player)
end, false)
