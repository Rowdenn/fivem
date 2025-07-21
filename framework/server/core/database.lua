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
                Framework.Debug:Warn(('Database connection attempt %d/%d failed: %s'):format(attempts, maxAttempts, tostring(response)))
                
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


-- Crée les tables de base
function Framework.Database:CreateTables()
    local tables = {
        -- utilisateurs
        [[
        CREATE TABLE IF NOT EXISTS `users` (
            `identifier` VARCHAR(50) PRIMARY KEY,
            `firstname` VARCHAR(50) NOT NULL,
            `lastname` VARCHAR(50) NOT NULL,
            `dateofbirth` DATE NOT NULL,
            `sex` VARCHAR(1) NOT NULL DEFAULT 'M',
            `height` INT NOT NULL DEFAULT 180,
            `job` VARCHAR(50) NOT NULL DEFAULT 'unemployed',
            `job_grade` INT NOT NULL DEFAULT 0,
            `money` INT NOT NULL DEFAULT 5000,
            `bank` INT NOT NULL DEFAULT 10000,
            `position` TEXT,
            `skin` LONGTEXT,
            `status` LONGTEXT,
            `last_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]],
        
        -- métiers
        [[
        CREATE TABLE IF NOT EXISTS `jobs` (
            `name` VARCHAR(50) PRIMARY KEY,
            `label` VARCHAR(100) NOT NULL,
            `whitelisted` BOOLEAN NOT NULL DEFAULT FALSE,
            `society` VARCHAR(50) DEFAULT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]],
        
        -- grades de métiers
        [[
        CREATE TABLE IF NOT EXISTS `job_grades` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `job_name` VARCHAR(50) NOT NULL,
            `grade` INT NOT NULL,
            `name` VARCHAR(50) NOT NULL,
            `label` VARCHAR(100) NOT NULL,
            `salary` INT NOT NULL DEFAULT 0,
            `permissions` TEXT,
            FOREIGN KEY (`job_name`) REFERENCES `jobs`(`name`) ON DELETE CASCADE,
            UNIQUE KEY `job_grade` (`job_name`, `grade`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]],
        
        -- métiers whitelist
        [[
        CREATE TABLE IF NOT EXISTS `job_whitelist` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(50) NOT NULL,
            `job` VARCHAR(50) NOT NULL,
            `added_by` VARCHAR(50) DEFAULT NULL,
            `added_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (`job`) REFERENCES `jobs`(`name`) ON DELETE CASCADE,
            UNIQUE KEY `identifier_job` (`identifier`, `job`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]],
        
        -- objets
        [[
        CREATE TABLE IF NOT EXISTS `items` (
            `name` VARCHAR(50) PRIMARY KEY,
            `label` VARCHAR(100) NOT NULL,
            `weight` INT NOT NULL DEFAULT 0,
            `rare` BOOLEAN NOT NULL DEFAULT FALSE,
            `canRemove` BOOLEAN NOT NULL DEFAULT TRUE,
            `canUse` BOOLEAN NOT NULL DEFAULT TRUE,
            `shouldClose` BOOLEAN NOT NULL DEFAULT TRUE,
            `combinable` TEXT,
            `description` TEXT,
            `image` VARCHAR(255),
            `decay` INT NOT NULL DEFAULT 0,
            `category` VARCHAR(50) DEFAULT 'misc'
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]],
        
        -- inventaires
        [[
        CREATE TABLE IF NOT EXISTS `inventories` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(50) NOT NULL,
            `item` VARCHAR(50) NOT NULL,
            `count` INT NOT NULL DEFAULT 0,
            `slot` INT NOT NULL DEFAULT 0,
            `metadata` TEXT,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (`item`) REFERENCES `items`(`name`) ON DELETE CASCADE,
            UNIQUE KEY `identifier_slot` (`identifier`, `slot`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]],
        
        -- véhicules
        [[
        CREATE TABLE IF NOT EXISTS `vehicles` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `owner` VARCHAR(50) NOT NULL,
            `plate` VARCHAR(8) NOT NULL UNIQUE,
            `vehicle` VARCHAR(50) NOT NULL,
            `model` VARCHAR(50) NOT NULL,
            `props` LONGTEXT,
            `garage` VARCHAR(50) DEFAULT 'pillboxhill',
            `fuel` INT NOT NULL DEFAULT 100,
            `engine` FLOAT NOT NULL DEFAULT 1000.0,
            `body` FLOAT NOT NULL DEFAULT 1000.0,
            `state` TINYINT NOT NULL DEFAULT 1,
            `impound` BOOLEAN NOT NULL DEFAULT FALSE,
            `impoundReason` TEXT,
            `impoundCost` INT DEFAULT 0,
            `lastUsed` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]],
        
        -- entreprises
        [[
        CREATE TABLE IF NOT EXISTS `societies` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `name` VARCHAR(50) NOT NULL UNIQUE,
            `label` VARCHAR(100) NOT NULL,
            `account` VARCHAR(50) NOT NULL UNIQUE,
            `money` INT NOT NULL DEFAULT 0,
            `boss` VARCHAR(50),
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]]
    }
    
    for i, query in ipairs(tables) do
        local success = self:Execute(query)
        if success then
            Framework.Debug:Info(('Table %d created successfully'):format(i))
        else
            Framework.Debug:Error(('Failed to create table %d'):format(i))
        end
    end
    
    -- Insère les données par défaut
    self:InsertDefaultData()
end

-- Insère les données par défaut
function Framework.Database:InsertDefaultData()
    -- Métiers par défaut
    local defaultJobs = {
        {name = 'unemployed', label = 'Chômeur', whitelisted = false},
        {name = 'police', label = 'Police', whitelisted = true},
        {name = 'ambulance', label = 'Ambulance', whitelisted = true},
        {name = 'mechanic', label = 'Mécanicien', whitelisted = false},
        {name = 'taxi', label = 'Taxi', whitelisted = false}
    }
    
    for _, job in pairs(defaultJobs) do
        self:Execute('INSERT IGNORE INTO jobs (name, label, whitelisted) VALUES (?, ?, ?)', {
            job.name, job.label, job.whitelisted
        })
    end
    
    -- Grades par défaut
    local defaultGrades = {
        {job_name = 'unemployed', grade = 0, name = 'unemployed', label = 'Chômeur', salary = 200},
        {job_name = 'police', grade = 0, name = 'recruit', label = 'Recrue', salary = 750},
        {job_name = 'police', grade = 1, name = 'officer', label = 'Officier', salary = 1000},
        {job_name = 'police', grade = 2, name = 'sergeant', label = 'Sergent', salary = 1250},
        {job_name = 'police', grade = 3, name = 'lieutenant', label = 'Lieutenant', salary = 1500},
        {job_name = 'police', grade = 4, name = 'captain', label = 'Capitaine', salary = 1750},
        {job_name = 'police', grade = 5, name = 'chief', label = 'Chef', salary = 2000},
        {job_name = 'ambulance', grade = 0, name = 'ambulance', label = 'Ambulancier', salary = 750},
        {job_name = 'ambulance', grade = 1, name = 'doctor', label = 'Médecin', salary = 1000},
        {job_name = 'ambulance', grade = 2, name = 'chief_doctor', label = 'Médecin Chef', salary = 1250},
        {job_name = 'mechanic', grade = 0, name = 'recrue', label = 'Recrue', salary = 500},
        {job_name = 'mechanic', grade = 1, name = 'novice', label = 'Novice', salary = 750},
        {job_name = 'mechanic', grade = 2, name = 'experimente', label = 'Expérimenté', salary = 1000},
        {job_name = 'mechanic', grade = 3, name = 'chief', label = 'Chef d\'équipe', salary = 1250},
        {job_name = 'mechanic', grade = 4, name = 'boss', label = 'Patron', salary = 1500},
        {job_name = 'taxi', grade = 0, name = 'recrue', label = 'Recrue', salary = 500},
        {job_name = 'taxi', grade = 1, name = 'novice', label = 'Novice', salary = 750},
        {job_name = 'taxi', grade = 2, name = 'experimente', label = 'Expérimenté', salary = 1000},
        {job_name = 'taxi', grade = 3, name = 'uber', label = 'Uber', salary = 1250},
        {job_name = 'taxi', grade = 4, name = 'boss', label = 'Patron', salary = 1500}
    }
    
    for _, grade in pairs(defaultGrades) do
        self:Execute('INSERT IGNORE INTO job_grades (job_name, grade, name, label, salary) VALUES (?, ?, ?, ?, ?)', {
            grade.job_name, grade.grade, grade.name, grade.label, grade.salary
        })
    end
    
    -- Objets par défaut
    local defaultItems = {
        {name = 'bread', label = 'Pain', weight = 125, canUse = true, shouldClose = true, description = 'Un bon pain frais'},
        {name = 'water', label = 'Eau', weight = 500, canUse = true, shouldClose = true, description = 'Une bouteille d\'eau'},
        {name = 'phone', label = 'Téléphone', weight = 190, canUse = true, shouldClose = false, description = 'Un téléphone portable'},
        {name = 'money', label = 'Argent liquide', weight = 0, canUse = false, shouldClose = false, description = 'De l\'argent en espèces'},
        {name = 'id_card', label = 'Carte d\'identité', weight = 5, canUse = true, shouldClose = false, description = 'Une carte d\'identité'},
        {name = 'driver_license', label = 'Permis de conduire', weight = 5, canUse = true, shouldClose = false, description = 'Un permis de conduire'},
        {name = 'bandage', label = 'Bandage', weight = 115, canUse = true, shouldClose = true, description = 'Un bandage médical'},
        {name = 'lockpick', label = 'Crochet', weight = 160, canUse = true, shouldClose = true, description = 'Un crochet pour forcer les serrures'},
        {name = 'handcuffs', label = 'Menottes', weight = 100, canUse = true, shouldClose = true, description = 'Des menottes en métal'},
        {name = 'pistol', label = 'Pistolet', weight = 970, canUse = true, shouldClose = true, description = 'Un pistolet'}
    }
    
    for _, item in pairs(defaultItems) do
        self:Execute('INSERT IGNORE INTO items (name, label, weight, canUse, shouldClose, description) VALUES (?, ?, ?, ?, ?, ?)', {
            item.name, item.label, item.weight, item.canUse, item.shouldClose, item.description
        })
    end
    
    Framework.Debug:Success('Default data inserted successfully')
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