local hunger = 100
local thirst = 100
local isLoaded = false
local isHudVisible = true

function ShouldShowMetabolismHud()
    if IsPauseMenuActive() then
        return false
    end

    if IsNuiFocused() then
        return false
    end

    return true
end

function ShowMetabolismHud()
    SendNUIMessage({
        action = "showModule",
        module = 'metabolism',
        data = {
            hunger = hunger,
            thirst = thirst
        }
    })
end

function HideMetabolismHud()
    SendNUIMessage({
        action = "hideModule",
        module = 'metabolism'
    })
end

function UpdateMetabolismHud(hungerValue, thirstValue)
    SendNUIMessage({
        action = "updateUI",
        module = 'metabolism',
        data = {
            hunger = hungerValue,
            thirst = thirstValue
        }
    })
end

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

Citizen.CreateThread(function()
    while true do
        local shouldShow = ShouldShowMetabolismHud()

        if shouldShow ~= isHudVisible then
            isHudVisible = shouldShow

            if isHudVisible then
                ShowMetabolismHud()
            else
                HideMetabolismHud()
            end
        end

        Citizen.Wait(100)
    end
end)

RegisterNetEvent('r_metabolism:updateValues')
AddEventHandler('r_metabolism:updateValues', function(data)
    hunger = data.hunger
    thirst = data.thirst

    if isHudVisible then
        UpdateMetabolismHud(hunger, thirst)
    end
end)

RegisterNetEvent('r_metabolism:lowValues')
AddEventHandler('r_metabolism:lowValues', function()
    if hunger == 0 then
        StartDeathProcess('hunger', 40)
        Citizen.SetTimeout(40000, function()
            TriggerServerEvent('r_metabolism:setValues', 50, 50)
        end) -- Wait 40 seconds
    end

    if thirst == 0 then
        StartDeathProcess('thirst', 40)
        Citizen.SetTimeout(40000, function()
            TriggerServerEvent('r_metabolism:setValues', 50, 50)
        end) -- Wait 40 seconds
    end
end)
