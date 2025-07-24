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
        type = 'updateValues',
        hunger = hunger,
        thirst = thirst
    })
end)

RegisterNetEvent('r_metabolism:lowValues')
AddEventHandler('r_metabolism:lowValues', function()
    print('Hunger:', hunger, 'Thirst:', thirst)
    if hunger == 0 then
        exports['r_coma']:StartDeathProcess('hunger', 40)
        Citizen.Wait(40000)  -- Wait 40 seconds
        TriggerServerEvent('r_metabolism:setValues', 50, 50)
    end

    if thirst == 0 then
        exports['r_coma']:StartDeathProcess('thirst', 40)
        Citizen.Wait(40000)  -- Wait 40 seconds
        TriggerServerEvent('r_metabolism:setValues', 50, 50)
    end
end)