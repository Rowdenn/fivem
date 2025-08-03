local Database = {
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
function WaitForReady(timeout)
    timeout = timeout or 30000 -- 30 secondes par défaut
    local startTime = GetGameTimer()

    while not Database.ready do
        if GetGameTimer() - startTime > timeout then
            return false
        end
        Wait(100)
    end

    return true
end

-- Initialisation de la base de données
function Init()
    -- Vérifier si oxmysql est disponible
    if not exports.oxmysql then
        return false
    end

    -- Attendre que oxmysql soit prêt
    CreateThread(function()
        local attempts = 0
        local maxAttempts = 10

        while attempts < maxAttempts do
            local success, response = pcall(function()
                return exports.oxmysql:executeSync("SELECT 1 as test")
            end)

            if success and response and response[1] and response[1].test == 1 then
                Database.ready = true
                break
            else
                attempts = attempts + 1

                if attempts >= maxAttempts then
                    return
                end

                Wait(2000) -- Attendre 2 secondes entre chaque tentative
            end
        end
    end)
end

-- Exécuter une requête SQL
function Execute(query, params, callback)
    local startTime = GetGameTimer()
    Database.stats.totalExecutions = Database.stats.totalExecutions + 1

    if callback then
        exports.oxmysql:execute(query, params, function(result)
            local queryTime = GetGameTimer() - startTime
            if queryTime > 100 then
                Database.stats.slowQueries = Database.stats.slowQueries + 1
            end
            callback(result)
        end)
    else
        local success, result = pcall(function()
            return exports.oxmysql:executeSync(query, params)
        end)

        local queryTime = GetGameTimer() - startTime
        if queryTime > 100 then
            Database.stats.slowQueries = Database.stats.slowQueries + 1
        end

        if not success then
            Database.stats.errors = Database.stats.errors + 1
            return false
        end

        return result
    end
end

-- Fait une requête SELECT
function Query(query, params, callback)
    local startTime = GetGameTimer()
    Database.stats.totalQueries = Database.stats.totalQueries + 1

    if callback then
        exports.oxmysql:execute(query, params, function(result)
            local queryTime = GetGameTimer() - startTime
            if queryTime > 100 then
                Database.stats.slowQueries = Database.stats.slowQueries + 1
            end
            callback(result)
        end)
    else
        local success, result = pcall(function()
            return exports.oxmysql:executeSync(query, params)
        end)

        local queryTime = GetGameTimer() - startTime
        if queryTime > 100 then
            Database.stats.slowQueries = Database.stats.slowQueries + 1
        end

        if not success then
            Database.stats.errors = Database.stats.errors + 1
            return nil
        end

        return result
    end
end

-- Récupère une seule ligne
function QuerySingle(query, params, callback)
    if callback then
        Query(query, params, function(result)
            callback(result and result[1] or nil)
        end)
    else
        local result = Query(query, params)
        return result and result[1] or nil
    end
end

-- Récupère une seule valeur
function QueryScalar(query, params, callback)
    if callback then
        QuerySingle(query, params, function(result)
            if result then
                local value = next(result)
                callback(result[value])
            else
                callback(nil)
            end
        end)
    else
        local result = QuerySingle(query, params)
        if result then
            local value = next(result)
            return result[value]
        end
        return nil
    end
end

-- Insère et récupère l'ID
function Insert(query, params, callback)
    if callback then
        exports.oxmysql:insert(query, params, function(insertId)
            callback(insertId)
        end)
    else
        local success, insertId = pcall(function()
            return exports.oxmysql:insertSync(query, params)
        end)

        if not success then
            Database.stats.errors = Database.stats.errors + 1
            return false
        end

        return insertId
    end
end

-- Effectue plusieurs requêtes
function Transaction(queries, callback)
    local startTime = GetGameTimer()
    Database.stats.totalQueries = Database.stats.totalQueries + 1

    if callback then
        exports.oxmysql:transaction(queries, function(success)
            local queryTime = GetGameTimer() - startTime
            if queryTime > 100 then
                Database.stats.slowQueries = Database.stats.slowQueries + 1
            end
            callback(success)
        end)
    else
        local success, result = pcall(function()
            return exports.oxmysql:transactionSync(queries)
        end)

        local queryTime = GetGameTimer() - startTime
        if queryTime > 100 then
            Database.stats.slowQueries = Database.stats.slowQueries + 1
        end

        if not success then
            Database.stats.errors = Database.stats.errors + 1
            return false
        end

        return result
    end
end

-- Prépare une requête (pour les requêtes répétées)
function Prepare(name, query)
    exports.oxmysql:prepare(name, query)
    Database.queries[name] = query
end

-- Exécute une requête préparée
function ExecutePrepared(name, params, callback)
    if not Database.queries[name] then
        return false
    end

    if callback then
        exports.oxmysql:execute(name, params, callback)
    else
        local success, result = pcall(function()
            return exports.oxmysql:executeSync(name, params)
        end)

        if not success then
            Database.stats.errors = Database.stats.errors + 1
            return false
        end

        return result
    end
end

-- Obtiens les statistiques
function GetStats()
    return Database.stats
end

-- Vérifie si la base est prête
function IsReady()
    return Database.ready
end

return Database
