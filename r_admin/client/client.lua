function IsValidVehicleModel(model)
    return IsModelInCdimage(model) and IsModelAVehicle(model)
end

RegisterNetEvent('r_admin:spawnVehicle')
AddEventHandler('r_admin:spawnVehicle', function(vehicleName) 
    local player = PlayerPedId()
    local playerCoords = GetEntityCoords(player)
    local playerHeading = GetEntityHeading(player)

    local vehicleHash = GetHashKey(vehicleName)

    if not IsValidVehicleModel(vehicleHash) then
        TriggerEvent('chat:addMessage', player, {
            color = {255, 0, 0},
            muiltine = true,
            args = {'Vehicule ' .. vehicleName .. ' introuvable'}
        })
    end

    RequestModel(vehicleHash)

    local timeout = 0
    while not HasModelLoaded(vehicleHash) and timeout < 50 do
        Citizen.Wait(100)
        timeout = timeout + 1
    end

    if not HasModelLoaded(vehicleHash) then
        TriggerEvent('chat:addMessage', player, {
            color = {255, 0, 0},
            muiltine = true,
            args = {'Impossible de charger le vehicule'}
        })
    return
    end

    local spawnCoords = GetOffsetFromEntityInWorldCoords(player, 0.0, 0.0, 0.0)
    local vehicle = CreateVehicle(vehicleHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, playerHeading, true, false)

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)

    TaskWarpPedIntoVehicle(player, vehicle, -1)

    SetModelAsNoLongerNeeded(vehicleHash)
end)

RegisterNetEvent('r_admin:fixVehicle')
AddEventHandler('r_admin:fixVehicle', function() 
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)

    if vehicle and vehicle ~= 0 then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleDirtLevel(vehicle, 0.0)
    end
end)