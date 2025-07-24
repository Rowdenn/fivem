local hunger = 100
local thirst = 100
local isLoaded = false

-- Initialise les valeurs de métabolisme
Citizen.CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(1000)
    end

    if not isLoaded then
        TriggerServerEvent('r_metabolism:playerLoaded')
        isLoaded = true
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
    if hunger == 0 then
        exports['r_coma']:StartDeathProcess('hunger', 40)
        Citizen.SetTimeout(40000, function()
            TriggerServerEvent('r_metabolism:setValues', 50, 50)
        end)  -- Wait 40 seconds
    end

    if thirst == 0 then
        exports['r_coma']:StartDeathProcess('thirst', 40)
        Citizen.SetTimeout(40000, function()
            TriggerServerEvent('r_metabolism:setValues', 50, 50)
        end)  -- Wait 40 seconds
    end
end)