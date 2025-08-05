function ShowNotification(data)
    if type(data) == "string" then
        data = {
            message = data,
            type = "info",
            duration = 5000,
            proximity = false
        }
    end

    data.duration = data.duration or 5000
    data.type = data.type or "info"
    data.image = data.image or nil

    SendNUIMessage({
        action = "showModule",
        module = 'notify',
        data = data
    })
end

RegisterNetEvent('r_notify:showNotification')
AddEventHandler('r_notify:showNotification', function(data)
    ShowNotification(data)
end)

local proximityNotificationVisible = false
local lastProximityMessage = ""

function ShowProximityNotification(message)
    if not proximityNotificationVisible or lastProximityMessage ~= message then
        proximityNotificationVisible = true
        lastProximityMessage = message
        SendNUIMessage({
            action = "showProximityNotification",
            data = {
                message = message,
                proximity = true
            }
        })
    end
end

function HideProximityNotification()
    if proximityNotificationVisible then
        proximityNotificationVisible = false
        lastProximityMessage = ""
        SendNUIMessage({
            action = "hideProximityNotification"
        })
    end
end

RegisterNetEvent('r_notify:showProximity')
AddEventHandler('r_notify:showProximity', function(message)
    ShowProximityNotification(message)
end)

RegisterNetEvent('r_notify:hideProximity')
AddEventHandler('r_notify:hideProximity', function()
    HideProximityNotification()
end)

-- Permet de gérer l'affichage des notifications plus facilement
local ProximityNotificationManager = {}
ProximityNotificationManager.__index = ProximityNotificationManager

function CreateProximityNotificationManager()
    local self = setmetatable({}, ProximityNotificationManager)
    self.lastTarget = nil
    return self
end

function ProximityNotificationManager:HandleNotification(currentTarget, getMessage, onInteract)
    if currentTarget then
        if self.lastTarget ~= currentTarget then
            local message = type(getMessage) == "function" and getMessage(currentTarget) or getMessage
            ShowProximityNotification(message)
            self.lastTarget = currentTarget
        end

        if onInteract and IsControlJustPressed(0, 38) then
            onInteract(currentTarget)
        end

        return 0
    else
        if self.lastTarget then
            HideProximityNotification()
            self.lastTarget = nil
        end

        return 1000
    end
end
