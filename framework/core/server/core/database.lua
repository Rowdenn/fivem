Framework.Database = {
    ready = false,
    queries = {},
    cache = {},
    stats = {
        totalQueries = 0,
        totalExecutions = 0,
        slowQueries = 0,
        errors = 0
    }
}

-- Attendre que la base soit prête
function Framework.Database:WaitForReady(timeout)
    timeout = timeout or 30000 -- 30 secondes par défaut
    local startTime = GetGameTimer()

    while not self.ready do
        if GetGameTimer() - startTime > timeout then
            Framework.Debug:Error('Database ready timeout after ' .. timeout .. 'ms')
            return false
        end
        Wait(100)
    end

    return true
end

-- Initialisation de la base de données
function Framework.Database:Init()
    -- Vérifier si oxmysql est disponible
    if not exports.oxmysql then
        Framework.Debug:Error('oxmysql not found! Please install oxmysql resource.')
        return false
    end

    Framework.Debug:Info('Initializing database connection...')

    -- Attendre que oxmysql soit prêt
    CreateThread(function()
        local attempts = 0
        local maxAttempts = 10

        while attempts < maxAttempts do
            local success, response = pcall(function()
                return exports.oxmysql:executeSync("SELECT 1 as test")
            end)

            if success and response and response[1] and response[1].test == 1 then
                self.ready = true
                Framework.Debug:Success('Database connection established successfully')
                self:CreateTables()
                break
            else
                attempts = attempts + 1
                Framework.Debug:Warn(('Database connection attempt %d/%d failed: %s'):format(attempts, maxAttempts,
                    tostring(response)))

                if attempts >= maxAttempts then
                    Framework.Debug:Error('Database connection failed after ' .. maxAttempts .. ' attempts')
                    return false
                end

                Wait(2000) -- Attendre 2 secondes entre chaque tentative
            end
        end
    end)
end

-- Exécuter une requête SQL
function Framework.Database:Execute(query, params, callback)
    local startTime = GetGameTimer()
    self.stats.totalExecutions = self.stats.totalExecutions + 1

    if callback then
        exports.oxmysql:execute(query, params, function(result)
            local queryTime = GetGameTimer() - startTime
            if queryTime > 100 then
                self.stats.slowQueries = self.stats.slowQueries + 1
                Framework.Debug:Warn(('Slow query detected: %dms - %s'):format(queryTime, query))
            end
            callback(result)
        end)
    else
        local success, result = pcall(function()
            return exports.oxmysql:executeSync(query, params)
        end)

        local queryTime = GetGameTimer() - startTime
        if queryTime > 100 then
            self.stats.slowQueries = self.stats.slowQueries + 1
            Framework.Debug:Warn(('Slow query detected: %dms - %s'):format(queryTime, query))
        end

        if not success then
            self.stats.errors = self.stats.errors + 1
            Framework.Debug:Error('Database error: ' .. tostring(result))
            return false
        end

        return result
    end
end

-- Fait une requête SELECT
function Framework.Database:Query(query, params, callback)
    local startTime = GetGameTimer()
    self.stats.totalQueries = self.stats.totalQueries + 1

    if callback then
        exports.oxmysql:execute(query, params, function(result)
            local queryTime = GetGameTimer() - startTime
            if queryTime > 100 then
                self.stats.slowQueries = self.stats.slowQueries + 1
                Framework.Debug:Warn(('Slow query detected: %dms - %s'):format(queryTime, query))
            end
            callback(result)
        end)
    else
        local success, result = pcall(function()
            return exports.oxmysql:executeSync(query, params)
        end)

        local queryTime = GetGameTimer() - startTime
        if queryTime > 100 then
            self.stats.slowQueries = self.stats.slowQueries + 1
            Framework.Debug:Warn(('Slow query detected: %dms - %s'):format(queryTime, query))
        end

        if not success then
            self.stats.errors = self.stats.errors + 1
            Framework.Debug:Error('Database error: ' .. tostring(result))
            return nil
        end

        return result
    end
end

-- Récupère une seule ligne
function Framework.Database:QuerySingle(query, params, callback)
    if callback then
        self:Query(query, params, function(result)
            callback(result and result[1] or nil)
        end)
    else
        local result = self:Query(query, params)
        return result and result[1] or nil
    end
end

-- Récupère une seule valeur
function Framework.Database:QueryScalar(query, params, callback)
    if callback then
        self:QuerySingle(query, params, function(result)
            if result then
                local value = next(result)
                callback(result[value])
            else
                callback(nil)
            end
        end)
    else
        local result = self:QuerySingle(query, params)
        if result then
            local value = next(result)
            return result[value]
        end
        return nil
    end
end

-- Insère et récupère l'ID
function Framework.Database:Insert(query, params, callback)
    if callback then
        exports.oxmysql:insert(query, params, function(insertId)
            callback(insertId)
        end)
    else
        local success, insertId = pcall(function()
            return exports.oxmysql:insertSync(query, params)
        end)

        if not success then
            self.stats.errors = self.stats.errors + 1
            Framework.Debug:Error('Database error: ' .. tostring(insertId))
            return false
        end

        return insertId
    end
end

-- Effectue plusieurs requêtes
function Framework.Database:Transaction(queries, callback)
    local startTime = GetGameTimer()
    self.stats.totalQueries = self.stats.totalQueries + 1

    if callback then
        exports.oxmysql:transaction(queries, function(success)
            local queryTime = GetGameTimer() - startTime
            if queryTime > 100 then
                self.stats.slowQueries = self.stats.slowQueries + 1
                Framework.Debug:Warn(('Slow transaction detected: %dms'):format(queryTime))
            end
            callback(success)
        end)
    else
        local success, result = pcall(function()
            return exports.oxmysql:transactionSync(queries)
        end)

        local queryTime = GetGameTimer() - startTime
        if queryTime > 100 then
            self.stats.slowQueries = self.stats.slowQueries + 1
            Framework.Debug:Warn(('Slow transaction detected: %dms'):format(queryTime))
        end

        if not success then
            self.stats.errors = self.stats.errors + 1
            Framework.Debug:Error('Database transaction error: ' .. tostring(result))
            return false
        end

        return result
    end
end

-- Prépare une requête (pour les requêtes répétées)
function Framework.Database:Prepare(name, query)
    exports.oxmysql:prepare(name, query)
    self.queries[name] = query
end

-- Exécute une requête préparée
function Framework.Database:ExecutePrepared(name, params, callback)
    if not self.queries[name] then
        Framework.Debug:Error('Prepared query not found: ' .. name)
        return false
    end

    if callback then
        exports.oxmysql:execute(name, params, callback)
    else
        local success, result = pcall(function()
            return exports.oxmysql:executeSync(name, params)
        end)

        if not success then
            self.stats.errors = self.stats.errors + 1
            Framework.Debug:Error('Database error: ' .. tostring(result))
            return false
        end

        return result
    end
end

-- Obtiens les statistiques
function Framework.Database:GetStats()
    return self.stats
end

-- Vérifie si la base est prête
function Framework.Database:IsReady()
    return self.ready
end

print('^2[Rowden Framework]^0 Database module loaded with oxmysql support')
