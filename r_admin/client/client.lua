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
