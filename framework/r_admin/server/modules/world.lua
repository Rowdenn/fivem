local currentWeather = 'CLEAR'

RegisterServerEvent('r_admin:changeWeather')
AddEventHandler('r_admin:changeWeather', function(weather, transitionTime)
    local source = source

    if not HasPermissionServer(source, 'weather_control') then
        return
    end

    currentWeather = weather
    transitionTime = transitionTime

    TriggerClientEvent('r_admin:syncWeather', -1, weather, transitionTime)
end)

RegisterServerEvent('r_admin:changeTime')
AddEventHandler('r_admin:changeTime', function(hour)
    local source = source

    if not HasPermissionServer(source, 'time_control') then
        return
    end

    TriggerClientEvent('r_admin:syncTime', -1, hour)
end)

AddEventHandler('playerLoaded', function()
    local source = source
    TriggerClientEvent('r_admin:syncWeather', source, currentWeather)
end)
