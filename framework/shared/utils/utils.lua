Framework.Utils = {
    cache = {},
    validators = {}
}

function Framework.Utils:Init()
    self:LoadValidators()
    Framework.Debug:Info('Utils system initialized')
end

function Framework.Utils:ValidateArgs(args, schema)
    if type(args) ~= 'table' or type(schema) ~= 'table' then
        return false, 'Invalid arg or schema'
    end

    for key, expectedType in pairs(schema) do
        local value = args[key]
        local actualType = type(value)

        -- On vérifie si la valeur est requise
        if expectedType:sub(1, 1) == '!' then
            expectedType = expectedType:sub(2)
            if value == nil then
                return false, ('Missing required arg: %s'):format(key)
            end
        end

        -- On vérifie si la valeur existe
        if value ~= nil then
            if expectedType == 'number' and actualType ~= 'number' then
                return false, ('Expected number for %s, got %s'):format(key, actualType)
            elseif expectedType == 'string' and actualType ~= 'string' then
                return false, ('Expected string for %s, got %s'):format(key, actualType)
            elseif expectedType == 'boolean' and actualType ~= 'boolean' then
                return false, ('Expected boolean for %s, got %s'):format(key, actualType)
            elseif expectedType == 'table' and actualType ~= 'table' then
                return false, ('Expected table for %s, got %s'):format(key, actualType)
            elseif expectedType == 'function' and actualType ~= 'function' then
                return false, ('Expected function for %s, got %s'):format(key, actualType)
            end
        end
    end

    return true, nil
end

-- Exemple d'utilisation : Framework.Utils:ValidateArgs({name = "test", age = 25}, {name = "!string", age = "number"})

-- Conversion d'une table au format JSON
function Framework.Utils:TableToJson(tbl)
    local success, result = pcall(json.encode, tbl)

    if success then
        return result
    else
        Framework.Debug:Error('Failed to encode table to JSON' .. result)
        return nil
    end
end

-- Conversion d'un JSON en table
function Framework.Utils:JsonToTable(jsonString)
    local success, result = pcall(json.decode, jsonString)

    if success then
        return result
    else
        Framework.Debug:Error('Failed to decode JSON' .. result)
        return nil
    end
end

-- Nettoyage des entrées des joueurs
-- function Framework.Utils:SanitizeInput(input)
--     if type(input) == 'string' then
--         input = input:gsub('[<>"\']', '')
--         input = input:match('^%s*(.-)%s*$')
--         if #input > 255 then
--             input = input:sub(1, 255)
--         end
--     end
--     return input
-- end

-- Copie totale d'une table
function Framework.Utils:DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == table then
            copy[k] = self:DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Fusion de tables
function Framework.Utils:MergeTables(t1, t2)
    local result = self:DeepCopy(t1)
    for k, v in pairs(t2) do
        if type(v) == 'table' and type(result[k]) == 'table' then
            result[k] = self:MergeTables(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

-- Vérifie si une table est vide
function Framework.Utils:IsTableEmpty(tbl)
    return next(tbl) == nil
end

-- Return la taille d'une table
function Framework.Utils:TableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- Recherche une valeur dans une table
function Framework.Utils:TableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Recherche une clé dans une table
function Framework.Utils:TableHasKey(tbl, key)
    return tbl[key] ~= nil
end

-- Convertie une table en string
function Framework.Utils:TableToString(tbl, indent)
    indent = indent or 0
    local spacing = string.rep('  ', indent)
    local result = {}
    
    table.insert(result, '{')
    for k, v in pairs(tbl) do
        local key = type(k) == 'string' and k or '[' .. tostring(k) .. ']'
        if type(v) == 'table' then
            table.insert(result, spacing .. '  ' .. key .. ' = ' .. self:TableToString(v, indent + 1))
        else
            local value = type(v) == 'string' and '"' .. v .. '"' or tostring(v)
            table.insert(result, spacing .. '  ' .. key .. ' = ' .. value)
        end
    end
    table.insert(result, spacing .. '}')
    
    return table.concat(result, '\n')
end

-- Génère un UUID
function Framework.Utils:GenerateUUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

-- Génère un ID aléatoire
function Framework.Utils:GenerateId(length)
    length = length or 8
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    local result = {}
    
    for i = 1, length do
        local randomIndex = math.random(1, #chars)
        table.insert(result, chars:sub(randomIndex, randomIndex))
    end
    
    return table.concat(result)
end

-- Permet de formatter les nombres avec des séparateurs
function Framework.Utils:FormatNumber(num, separator)
    separator = separator or ','
    local formatted = tostring(num)
    
    -- Ajouter les séparateurs de milliers
    while true do
        formatted, k = formatted:gsub('^(-?%d+)(%d%d%d)', '%1' .. separator .. '%2')
        if k == 0 then break end
    end
    
    return formatted
end

-- Permet de formatter l'argent
function Framework.Utils:FormatMoney(amount, currency)
    currency = currency or '$'
    return currency .. self:FormatNumber(amount)
end

-- Calcul la distance entre deux points
function Framework.Utils:GetDistance(coords1, coords2)
    if type(coords1) ~= 'table' or type(coords2) ~= 'table' then
        return 0
    end
    
    local dx = coords1.x - coords2.x
    local dy = coords1.y - coords2.y
    local dz = coords1.z - coords2.z
    
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Calcul la distance 2D
function Framework.Utils:GetDistance2D(coords1, coords2)
    if type(coords1) ~= 'table' or type(coords2) ~= 'table' then
        return 0
    end
    
    local dx = coords1.x - coords2.x
    local dy = coords1.y - coords2.y
    
    return math.sqrt(dx * dx + dy * dy)
end

-- Arrondie un nombre 
function Framework.Utils:Round(num, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(num * mult + 0.5) / mult
end

-- Interpole deux valeurs 
function Framework.Utils:Lerp(a, b, t)
    return a + (b - a) * t
end

-- Clamp une valeur entre min et max
function Framework.Utils:Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Vérifie sur une valeur est un nombre
function Framework.Utils:IsNumber(value)
    return type(value) == 'number' and value == value -- NaN check
end

-- Vérifie si une chaine est vide
function Framework.Utils:IsStringEmpty(str)
    return not str or str == '' or str:match('^%s*$') ~= nil
end

-- Escape les caractères spéciaux pour les patterns lua
function Framework.Utils:EscapePattern(str)
    return str:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%1')
end

-- Divise une chaîne
function Framework.Utils:Split(str, delimiter)
    delimiter = delimiter or '%s'
    local result = {}
    for match in str:gmatch('([^' .. delimiter .. ']+)') do
        table.insert(result, match)
    end
    return result
end

-- Obtiens le timestamp actuel
function Framework.Utils:GetTimestamp()
    return os.time()
end

-- Formatte un timestamp
function Framework.Utils:FormatTimestamp(timestamp, format)
    format = format or '%Y-%m-%d %H:%M:%S'
    return os.date(format, timestamp)
end

-- Système de mise en cache
function Framework.Utils:SetCache(key, value, ttl)
    ttl = ttl or 300 -- 5 minutes par défaut
    self.cache[key] = {
        value = value,
        expires = GetGameTimer() + (ttl * 1000)
    }
end

function Framework.Utils:GetCache(key)
    local cached = self.cache[key]
    if not cached then return nil end
    
    if GetGameTimer() > cached.expires then
        self.cache[key] = nil
        return nil
    end
    
    return cached.value
end

function Framework.Utils:ClearCache(key)
    if key then
        self.cache[key] = nil
    else
        self.cache = {}
    end
end

-- Load les validateurs
function Framework.Utils:LoadValidators()
    -- Validateur d'email
    self.validators.email = function(email)
        local pattern = '^[%w%._%+%-]+@[%w%._%+%-]+%.%w+$'
        return email:match(pattern) ~= nil
    end
    
    -- Validateur de numéro de téléphone
    self.validators.phone = function(phone)
        local pattern = '^%+?[%d%s%-%(%)]+$'
        return phone:match(pattern) ~= nil and #phone >= 10
    end
    
    -- Validateur de mot de passe
    self.validators.password = function(password)
        return #password >= 8 and 
               password:match('%d') and 
               password:match('%a') and 
               password:match('[%W_]')
    end
    
    -- Validateur d'identifiant
    self.validators.identifier = function(identifier)
        local pattern = '^[%w_%-]+$'
        return identifier:match(pattern) ~= nil and #identifier >= 3
    end
end

-- Valide une donnée
function Framework.Utils:Validate(data, validatorType)
    local validator = self.validators[validatorType]
    if not validator then
        Framework.Debug:Warn('Unknown validator type: ' .. validatorType)
        return false
    end
    
    return validator(data)
end

function Framework.Utils:GetCoords()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)

    return coords
end

RegisterCommand('coords', function()
    print(Framework.Utils:GetCoords())
end, false)

print('^2[Rowden Framework]^0 Utils system loaded')