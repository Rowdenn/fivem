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

RegisterCommand("giveweapon", function(source, args, rawCommand)
    local playerPed = PlayerPedId()

    if not args[1] then
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            multiline = true,
            args = { "ERREUR", "Usage: /giveweapon [nom_arme] [munitions(optionnel)]" }
        })
        return
    end

    local weaponName = string.upper(args[1])
    local ammo = tonumber(args[2]) or 250

    if not string.find(weaponName, "WEAPON_") then
        weaponName = "WEAPON_" .. weaponName
    end

    local weaponHash = GetHashKey(weaponName)

    GiveWeaponToPed(playerPed, weaponHash, ammo, false, true)

    TriggerEvent('chat:addMessage', {
        color = { 0, 255, 0 },
        multiline = true,
        args = { "SUCCÈS", "Arme " .. weaponName .. " ajoutée avec " .. ammo .. " munitions!" }
    })
end, false)
