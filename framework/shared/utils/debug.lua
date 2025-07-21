-- =============================================
-- SYSTÈME DE DEBUG - FRAMEWORK
-- =============================================

Framework.Debug = {
    enabled = Config.Debug or false,
    levels = {
        DEBUG = 0,
        INFO = 1,
        WARN = 2,
        ERROR = 3,
        SUCCESS = 4,
    },

    colors = {
        DEBUG = '^8', -- Gris
        INFO = '^5', -- Bleu
        WARN = '^3', -- Jaune
        ERROR = '^1', -- Rouge
        SUCCESS = '^2', -- Vert
        RESET = '^0' -- Reset
    },
    logFile = nil,
    logBuffer = {},
    maxBufferSize = 1000
}

-- Fonction pour obtenir le timestamp selon le côté
local function GetTimestamp()
    if IsDuplicityVersion() then
        -- Côté serveur
        return os.date('%d-%m-%Y %H:%M:%S')
    else
        -- Côté client - utiliser une approximation
        local hours = GetClockHours()
        local minutes = GetClockMinutes()
        local seconds = GetClockSeconds()
        local day = GetClockDayOfMonth()
        local month = GetClockMonth()
        local year = GetClockYear()
        
        return string.format('%02d-%02d-%04d %02d:%02d:%02d', day, month, year, hours, minutes, seconds)
    end
end

-- Système de debug
function Framework.Debug:Init()
    self.logBuffer = {}
    self.maxBufferSize = Config.Logging and Config.Logging.maxBufferSize or 1000
    
    -- Seul le serveur peut écrire dans les fichiers
    if IsDuplicityVersion() and Config.Logging and Config.Logging.logToFile then
        self:CreateLogDirectory()
        local logPath = ('logs/%s.log'):format(os.date('%Y-%m-%d'))
        self.logFile = io.open(logPath, 'a')
        if not self.logFile then
            print('^1[FRAMEWORK] ^7Impossible d\'ouvrir le fichier de log: ' .. logPath)
        end
    end
    
    local side = IsDuplicityVersion() and 'SERVER' or 'CLIENT'
    print('^2[FRAMEWORK]^7 Debug system initialized on ' .. side)
end

-- Crée le dossier des logs (côté serveur seulement)
function Framework.Debug:CreateLogDirectory()
    if not IsDuplicityVersion() then return end
    
    -- Créer le dossier logs s'il n'existe pas
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    if resourcePath then
        local logDir = resourcePath .. '/logs'
        -- Note: La création de dossier dépend du système d'exploitation
        -- Pour l'instant, on assume que le dossier existe
    end
end

-- Fonction pour formater le message
function Framework.Debug:FormatMessage(level, message, source)
    local timestamp = GetTimestamp()
    local sourceStr = source and (' [%s]'):format(source) or ''
    local side = IsDuplicityVersion() and 'SERVER' or 'CLIENT'
    
    return ('%s%s [%s][%s]%s %s%s'):format(
        self.colors[level] or '',
        timestamp,
        side,
        level,
        sourceStr,
        message,
        self.colors.RESET
    )
end

-- Ajoute au buffer
function Framework.Debug:AddToBuffer(message)
    if not self.logBuffer then
        self.logBuffer = {}
    end
    
    table.insert(self.logBuffer, {
        message = message,
        timestamp = IsDuplicityVersion() and os.time() or GetGameTimer()
    })
    
    -- Limite la taille du buffer
    if #self.logBuffer > self.maxBufferSize then
        table.remove(self.logBuffer, 1)
    end
end

-- Fonction principale de log
function Framework.Debug:Log(level, message, source)
    if not self.enabled then return end
    
    local formattedMessage = self:FormatMessage(level, message, source)
    
    -- Affichage console
    print(formattedMessage)
    
    -- Ajout au buffer
    self:AddToBuffer(formattedMessage)
    
    -- Écriture dans le fichier (côté serveur uniquement)
    if IsDuplicityVersion() and self.logFile then
        self.logFile:write(formattedMessage .. '\n')
        self.logFile:flush()
    end
end

-- Fonctions de debug par niveau
function Framework.Debug:Debug(message, source)
    self:Log('DEBUG', message, source)
end

function Framework.Debug:Info(message, source)
    self:Log('INFO', message, source)
end

function Framework.Debug:Warn(message, source)
    self:Log('WARN', message, source)
end

function Framework.Debug:Error(message, source)
    self:Log('ERROR', message, source)
end

function Framework.Debug:Success(message, source)
    self:Log('SUCCESS', message, source)
end

-- Fonction pour dump une table
function Framework.Debug:Dump(data, label)
    if not self.enabled then return end
    
    local label = label or 'Data dump'
    local output = {}
    
    local function serialize(obj, indent)
        local indent = indent or 0
        local spacing = string.rep('  ', indent)
        
        if type(obj) == 'table' then
            table.insert(output, '{\n')
            for k, v in pairs(obj) do
                table.insert(output, spacing .. '  ')
                if type(k) == 'string' then
                    table.insert(output, '["' .. k .. '"] = ')
                else
                    table.insert(output, '[' .. tostring(k) .. '] = ')
                end
                serialize(v, indent + 1)
                table.insert(output, ',\n')
            end
            table.insert(output, spacing .. '}')
        elseif type(obj) == 'string' then
            table.insert(output, '"' .. obj .. '"')
        else
            table.insert(output, tostring(obj))
        end
    end
    
    serialize(data)
    local result = table.concat(output)
    
    self:Debug(label .. ':\n' .. result)
end

-- Fonction pour obtenir les logs du buffer
function Framework.Debug:GetLogs(count)
    local count = count or 50
    local logs = {}
    local startIndex = math.max(1, #self.logBuffer - count + 1)
    
    for i = startIndex, #self.logBuffer do
        table.insert(logs, self.logBuffer[i])
    end
    
    return logs
end

-- Fonction pour vider le buffer
function Framework.Debug:ClearBuffer()
    self.logBuffer = {}
end

-- Fonction pour fermer le fichier de log
function Framework.Debug:Close()
    if self.logFile then
        self.logFile:close()
        self.logFile = nil
    end
end

-- Fonction pour tracer les performances
function Framework.Debug:StartTimer(name)
    if not self.enabled then return end
    
    if not self.timers then
        self.timers = {}
    end
    
    self.timers[name] = IsDuplicityVersion() and os.clock() or GetGameTimer()
end

function Framework.Debug:EndTimer(name)
    if not self.enabled or not self.timers or not self.timers[name] then return end
    
    local startTime = self.timers[name]
    local endTime = IsDuplicityVersion() and os.clock() or GetGameTimer()
    local duration = endTime - startTime
    
    local unit = IsDuplicityVersion() and 'seconds' or 'ms'
    self:Debug(('Timer [%s]: %.2f %s'):format(name, duration, unit))
    
    self.timers[name] = nil
end

-- Fonction pour debug les événements
function Framework.Debug:TraceEvent(eventName, source, data)
    if not self.enabled then return end
    
    local side = IsDuplicityVersion() and 'SERVER' or 'CLIENT'
    local sourceStr = source and (' from %s'):format(source) or ''
    
    self:Debug(('Event [%s] triggered on %s%s'):format(eventName, side, sourceStr))
    
    if data then
        self:Dump(data, 'Event data')
    end
end

-- Fonction pour debug les erreurs SQL
function Framework.Debug:SQLError(query, error)
    if not self.enabled then return end
    
    self:Error(('SQL Error: %s'):format(error))
    self:Debug(('Failed Query: %s'):format(query))
end

-- Fonction pour debug les connexions/déconnexions
function Framework.Debug:PlayerConnection(source, action, identifier)
    if not self.enabled then return end
    
    local message = ('Player %s [%s] - %s'):format(source, identifier or 'unknown', action)
    self:Info(message)
end

-- Initialisation automatique
if Framework and Framework.Debug then
    Framework.Debug:Init()
end
