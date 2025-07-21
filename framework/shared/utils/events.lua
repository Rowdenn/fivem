Framework.Events = {
    registered = {},
    callbacks = {},
    callbackId = 0,
    rateLimiter = {},
    eventQueue = {},
    processing = false
}

-- Initialise le système d'events
function Framework.Events:Init()
    self:SetupRateLimiter()
    self:RegisterDefaultEvents()
    Framework.Debug:Info('Events system initialized')
end

-- Configuration du rate limiter
function Framework.Events:SetupRateLimiter()
    if not Config.Events.enableAntiSpam then return end
    
    -- Nettoyage périodique du rate limiter
    CreateThread(function()
        while true do
            Wait(60000)
            local currentTime = GetGameTimer()
            
            for source, data in pairs(self.rateLimiter) do
                if currentTime - data.lastReset > 60000 then
                    self.rateLimiter[source] = nil
                end
            end
        end
    end)
end

-- Vérifie le rate limit
function Framework.Events:CheckRateLimit(source)
    if not Config.Events.enableAntiSpam then return true end
    
    local currentTime = GetGameTimer()
    local sourceData = self.rateLimiter[source]
    
    if not sourceData then
        self.rateLimiter[source] = {
            count = 1,
            lastReset = currentTime
        }
        return true
    end
    
    -- Reset si plus d'une seconde s'est écoulée
    if currentTime - sourceData.lastReset > 1000 then
        sourceData.count = 1
        sourceData.lastReset = currentTime
        return true
    end
    
    sourceData.count = sourceData.count + 1
    
    if sourceData.count > Config.Events.maxEventsPerSecond then
        Framework.Debug:Warn(('Rate limit exceeded for source: %s'):format(source))
        return false
    end
    
    return true
end

-- Enregistre un event
function Framework.Events:Register(eventName, callback, context)
    if not eventName or not callback then
        Framework.Debug:Error('Invalid event registration: missing eventName or callback')
        return false
    end
    
    RegisterNetEvent(eventName)
    
    local wrappedCallback = function(...)
        local source = source or 'unknown'
        
        if not self:CheckRateLimit(source) then
            return
        end
        
        local args = {...}
        if Config.Events.enableValidation then
            for i, arg in ipairs(args) do
                if type(arg) == 'string' then
                    args[i] = Framework.Utils:SanitizeInput(arg)
                end
            end
        end
        
        if Config.Events.enableLogging then
            Framework.Debug:Debug(('Event triggered: %s from %s'):format(eventName, source))
        end
        
        local success, result = pcall(callback, table.unpack(args))
        if not success then
            Framework:HandleError(result, eventName)
        end
        
        -- Incrémente les stats
        Framework.State.stats.eventsTriggered = Framework.State.stats.eventsTriggered + 1
    end
    
    AddEventHandler(eventName, wrappedCallback)
    
    self.registered[eventName] = {
        callback = callback,
        context = context,
        registeredAt = GetGameTimer()
    }
    
    Framework.Debug:Debug(('Event registered: %s'):format(eventName))
    return true
end
