function ShowNotification(data)
    if type(data) == "string" then
        data = {
            message = data,
            type = "info",
            duration = 5000
        }
    end

    data.duration = data.duration or 5000
    data.type = data.type or "info"
    data.image = data.image or nil

    SendNUIMessage({
        action = "showNotification",
        data = data
    })
end

RegisterNetEvent('r_notify:showNotification')
AddEventHandler('r_notify:showNotification', function(data)
    ShowNotification(data)
end)

exports('ShowNotification', ShowNotification)
