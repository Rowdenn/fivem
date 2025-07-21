if not Framework then
    Framework = {}
end

if Framework.Debug then
    Framework.Debug:Init()
end

-- Initialisation du Framework
Framework = {}
Framework.Version = Config.Version.string
Framework.Ready = false
Framework.StartTime = GetGameTimer()

-- Modules
Framework.Utils = {}
Framework.Events = {}
Framework.Modules = {}
Framework.Locales = {}
Framework.Debug = {}
Framework.Performance = {}

-- State
Framework.State = {
    initialized = false,
    modulesLoaded = {},
    errors = {},
    warnings = {},
    stats = {
        startTime = GetGameTimer(),
        eventsTriggered = 0,
        errorCount = 0,
        warningCount = 0
    }
}

-- Init
function Framework:Init()
    if self.state.initialized then
        self.Debug:Warn('Framwork already initialized')
        return false
    end

    -- On charge les modules essentiels
    self:LoadEssentialModules()

    self.State.initialized = true
    self.Ready = true

    self.Debug:Success('Framework initialized successfully')
    self:TriggerEvent('framework:ready')

    return true
end

-- Modules essentiels
function Framework:LoadEssentialModules()
    self.Debug:Init()
    self.Utils:Init()
    self.Events:Init()
    self.Locales:Init()
    self.Performance:Init()
    self.Debug:Info('Essential modules loaded')
end

-- Déclencheur d'event
function Framework:TriggerEvent(eventName, ...)
    self.Events:Trigger(eventName, ...)
end

-- Trad
function Framework:GetLocale(key, ...)
    return self.Locales:Get(key, ...)
end

-- Stats
function Framework:GetStats() 
    local currentTime = GetGameTimer()
    local uptime = currentTime - self.State.stats.startTime

    return {
        uptime = uptime,
        eventsTriggered = self.State.stats.eventsTriggered,
        warningCount = self.State.stats.warningCount,
        modulesLoaded = #self.State.stats.modulesLoaded,
        memoryUsage = collectgarbage('count'),
        ready = self.ready
    }
end

-- Stop le framework
function Framework:Shutdown()
    self.Debug:Info('Shutting down framework...')

    self:TriggerEvent('framework:shutdown')

    for moduleName, _ in pairs(self.State.modulesLoaded) do
        if self.Modules[moduleName] and self.Modules[moduleName].Shutdown then
            self.Modules[moduleName]:Shutdown()
        end
    end

    self.Ready = false
    self.Debug:Success('Framework shutdown complete')
end

-- Gestion des erreurs
function Framework:HandleError(error, context)
    self.State.stats.errorCount = self.State.stats.errorCount + 1
    self.State.error[#self.State.error+1] = {
        error = error,
        context = context or 'unknown',
        timestamp = os.time()
    }

    self.Debug:Error(('Error in %s: %s'):format(context or 'unknown', error))

    self:TriggerEvent('framework:error', error, context)
end

-- Gestion des warnings
function Framework:HandleWarning(warning, context)
    self.State.stats.warningCount = self.State.stats.warningCount + 1
    self.State.warning[#self.State.warning+1] = {
        warning = warning,
        context = context or 'unknown',
        timestamp = os.time()
    }

    self.Debug:Warn(('Warning in %s: %s'):format(context or 'unknown', warning))

    self:TriggerEvent('framework:warning', warning, context)
end

_G.Framework = Framework
exports('GetFramework', function() return Framework end)

print('^2[Rowden Framework]^0 Core loaded successfully')