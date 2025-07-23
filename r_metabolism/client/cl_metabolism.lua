local hunger = 100
local thirst = 100

-- Initialise les valeurs de métabolisme
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if NetworkIsPlayerActive(PlayerId()) then
            TriggerServerEvent('r_metabolism:playerLoaded')
        end
    end
end)

RegisterNetEvent('r_metabolism:updateValues')
AddEventHandler('r_metabolism:updateValues', function(data)
    hunger = data.hunger
    thirst = data.thirst

    SendNUIMessage({
        action = 'updateValues',
        hunger = hunger,
        thirst = thirst
    })
end)

RegisterNetEvent('r_metabolism:lowValues')
AddEventHandler('r_metabolism:lowValues', function()
    local player = PlayerPedId()

    if hunger == 0 then
        local health = GetEntityHealth(player)
        if health > 0 then
            SetEntityHealth(player, health - 10)
        end
    end

    if thirst == 0 then
        local health = GetEntityHealth(player)
        if health > 0 then
            SetEntityHealth(player, health - 10)
        end
    end
end)

exports('getHunger', function()
    return hunger
end)

exports('getThirst', function()
    return thirst
end)