local weatherTypes = {
    { label = 'EXTRASUNNY' },
    { label = 'CLEAR' },
    { label = 'NEUTRAL' },
    { label = 'SMOG' },
    { label = 'FOGGY' },
    { label = 'OVERCAST' },
    { label = 'CLOUDS' },
    { label = 'CLEARING' },
    { label = 'RAIN' },
    { label = 'THUNDER' },
    { label = 'SNOW' },
    { label = 'BLIZZARD' },
    { label = 'SNOWLIGHT' },
    { label = 'XMAS' },
    { label = 'HALLOWEEN' }
}

local isTransitioning = false
local selectedHour = 12

function OpenWorldMenu()
    local worldMenu = MenuV:CreateMenu("Monde", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    local initialWeatherIndex = 1
    local selectedWeather

    local weatherSlider = worldMenu:AddSlider({
        icon = '🌤️',
        label = 'Météo',
        value = initialWeatherIndex,
        values = weatherTypes,
        description = 'Changer les conditions météorologiques',
        select = function()
            TriggerServerEvent('r_admin:changeWeather', selectedWeather, 30000)
        end
    })

    -- * Récupèrer la valeur actuelle avec l'option select ne fonctionne pas, on doit passer par change pour attribuer la valeur à une variable
    weatherSlider:On('change', function(uuid, key, currentValue, oldValue)
        selectedWeather = weatherTypes[currentValue].label
    end)

    local hourValues = {}
    for i = 0, 23 do
        table.insert(hourValues, {
            label = string.format("%02dh", i),
            value = i
        })
    end

    local timeSlider = worldMenu:AddSlider({
        icon = '🕐',
        label = 'Changer l\'heure',
        description = 'Modifier l\'heure du serveur',
        values = hourValues,
        value = 13,
        select = function()
            TriggerServerEvent('r_admin:changeTime', selectedHour)
        end
    })

    timeSlider:On('change', function(uuid, key, currentValue, oldValue)
        selectedHour = currentValue - 1
    end)

    worldMenu:Open()
end

RegisterNetEvent('r_admin:syncWeather')
AddEventHandler('r_admin:syncWeather', function(weather, transitionTime)
    if isTransitioning then
        TriggerServerEvent('r_admin:client:showNotification', 'La météo est déjà en cours de transition', 'error')
        return
    end

    isTransitioning = true

    if transitionTime and transitionTime > 0 then
        SetWeatherTypeOvertimePersist(weather, transitionTime / 1000)
        TriggerServerEvent('r_admin:client:showNotification',
            'Changement de la météo pour ' .. weather, 'info')

        Citizen.SetTimeout(transitionTime, function()
            isTransitioning = false
            TriggerServerEvent('r_admin:client:showNotification', "Transition de la météo terminée", 'success')
        end)
    end
end)

RegisterNetEvent('r_admin:syncTime')
AddEventHandler('r_admin:syncTime', function(hour)
    NetworkOverrideClockTime(hour, 0, 0)
    TriggerServerEvent('r_admin:client:showNotification', "Heure changée pour " .. string.format("%02dh", hour),
        "success")
end)
