RegisterCommand('car', function(source, args)
    local player = source

    if not args[1] then
        TriggerClientEvent('chat:addMessage', player, {
            color = {255, 0, 0},
            muiltine = true,
            args = {'Utilisation: /car <nom_du_vehicule)'}
        })
    end

    local vehicleName = args[1]:lower()

    TriggerClientEvent('r_admin:spawnVehicle', player, vehicleName)
end, false)

RegisterCommand('fix', function(source, args)
    local player = source
    TriggerClientEvent('r_admin:fixVehicle', player, vehicleName)
end, false)