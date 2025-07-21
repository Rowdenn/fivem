Framework.Players = {}
Framework.Players.list = {}
Framework.Players.identifiers = {}

-- Données par défaut d'un joueur
Framework.Players.defaultData = {
    firstname = '',
    lastname = '',
    dateofbirth = '',
    sex = 'm',
    height = 180,
    job = 'unemployed',
    job_grade = 0,
    gang = 'none',
    gang_grade = 0,
    position = {x = -1035.71, y = -2731.87, z = 12.86, heading = 0.0},
    metadata = {},
    status = {hunger = 100, thirst = 100, health = 200, armor = 0},
    is_dead = false
}

local Player = {}
Player.__index = Player

function Player:new(source, identifier, data)
    local self = setmetatable({}, Player)
    
    -- Identifiants
    self.source = source
    self.identifier = identifier
    self.license = data.license or identifier
    self.steam = data.steam or ''
    self.discord = data.discord or ''
    
    -- Informations personnelles
    self.name = data.name or GetPlayerName(source)
    self.firstname = data.firstname or ''
    self.lastname = data.lastname or ''
    self.dateofbirth = data.dateofbirth or ''
    self.sex = data.sex or 'm'
    self.height = data.height or 180
    
    -- Argent
    self.money = tonumber(data.money) or 0
    self.bank = tonumber(data.bank) or 0
    self.black_money = tonumber(data.black_money) or 0
    
    -- Travail
    self.job = data.job or 'unemployed'
    self.job_grade = tonumber(data.job_grade) or 0
    self.gang = data.gang or 'none'
    self.gang_grade = tonumber(data.gang_grade) or 0
    
    -- Position
    self.position = data.position and json.decode(data.position) or Framework.Players.defaultData.position
    
    -- Métadonnées
    self.metadata = data.metadata and json.decode(data.metadata) or {}
    self.status = data.status and json.decode(data.status) or Framework.Players.defaultData.status
    
    -- État
    self.is_dead = data.is_dead or false
    self.group = 'user'
    self.permissions = {}
    
    -- Charger les permissions
    self:LoadPermissions()
    
    return self
end

-- Sauvegarder le joueur
function Player:Save()
    local query = [[
        UPDATE users SET 
            name = ?, firstname = ?, lastname = ?, dateofbirth = ?, sex = ?, height = ?,
            money = ?, bank = ?, black_money = ?, job = ?, job_grade = ?, gang = ?, gang_grade = ?,
            position = ?, metadata = ?, status = ?, is_dead = ?
        WHERE identifier = ?
    ]]
    
    local values = {
        self.name, self.firstname, self.lastname, self.dateofbirth, self.sex, self.height,
        self.money, self.bank, self.black_money, self.job, self.job_grade, self.gang, self.gang_grade,
        json.encode(self.position), json.encode(self.metadata), json.encode(self.status), self.is_dead,
        self.identifier
    }
    
    Framework.Database.execute(query, values, function(result)
        if result.affectedRows > 0 then
            Framework.Debug.Success(('Player saved: %s'):format(self.identifier))
            return true
        else
            Framework.Debug.Error(('Failed to save player: %s'):format(self.identifier))
            return false
        end
    end)
    
    return true
end

-- Ajouter de l'argent
function Player:AddMoney(amount, reason)
    if not amount or amount <= 0 then return false end
    
    local oldMoney = self.money
    self.money = self.money + amount
    
    -- Log de transaction
    Framework.Database.execute('INSERT INTO logs (type, identifier, action, data) VALUES (?, ?, ?, ?)', {
        'money',
        self.identifier,
        'money_added',
        json.encode({
            amount = amount,
            old_amount = oldMoney,
            new_amount = self.money,
            reason = reason or 'unknown'
        })
    })
    
    -- Notification
    self:Notify(('Vous avez reçu $%s'):format(Framework.Utils.FormatMoney(amount)), 'success')
    
    return true
end

-- Retirer de l'argent
function Player:RemoveMoney(amount, reason)
    if not amount or amount <= 0 then return false end
    if self.money < amount then return false end
    
    local oldMoney = self.money
    self.money = self.money - amount
    
    -- Log de transaction
    Framework.Database.execute('INSERT INTO logs (type, identifier, action, data) VALUES (?, ?, ?, ?)', {
        'money',
        self.identifier,
        'money_removed',
        json.encode({
            amount = amount,
            old_amount = oldMoney,
            new_amount = self.money,
            reason = reason or 'unknown'
        })
    })
    
    -- Notification
    self:Notify(('Vous avez payé $%s'):format(Framework.Utils.FormatMoney(amount)), 'info')
    
    return true
end

-- Définir l'argent
function Player:SetMoney(amount, reason)
    if not amount or amount < 0 then return false end
    
    local oldMoney = self.money
    self.money = amount
    
    -- Log de transaction
    Framework.Database.execute('INSERT INTO logs (type, identifier, action, data) VALUES (?, ?, ?, ?)', {
        'money',
        self.identifier,
        'money_set',
        json.encode({
            old_amount = oldMoney,
            new_amount = self.money,
            reason = reason or 'unknown'
        })
    })
    
    return true
end

-- Getters
function Player:GetMoney()
    return self.money
end

function Player:GetBank()
    return self.bank
end

function Player:GetJob()
    return {
        name = self.job,
        grade = self.job_grade
    }
end

-- Notification
function Player:Notify(message, type, duration)
    TriggerClientEvent('framework:client:notify', self.source, message, type or 'info', duration or 5000)
end

-- Kick
function Player:Kick(reason)
    DropPlayer(self.source, reason or "Vous avez été kick")
end

-- Métadonnées
function Player:SetMetadata(key, value)
    self.metadata[key] = value
end

function Player:GetMetadata(key)
    return self.metadata[key]
end

-- Permissions
function Player:LoadPermissions()
    Framework.Database.fetchAll('SELECT * FROM user_permissions WHERE identifier = ?', {self.identifier}, function(userPermissions)
        if userPermissions and #userPermissions > 0 then
            for _, perm in pairs(userPermissions) do
                self.permissions[perm.permission] = true
            end
            self.group = userPermissions[1].group or 'user'
        else
            self.group = 'user'
        end
    end)
end

function Player:HasPermission(permission)
    if self.permissions[permission] then
        return true
    end
    
    local groupPermissions = Config.Permissions and Config.Permissions.groups and Config.Permissions.groups[self.group]
    if groupPermissions and groupPermissions.permissions then
        for _, perm in pairs(groupPermissions.permissions) do
            if perm == '*' or perm == permission then
                return true
            end
        end
    end
    
    return false
end

-- Récupérer les données
function Player:GetData()
    return {
        source = self.source,
        identifier = self.identifier,
        license = self.license,
        steam = self.steam,
        discord = self.discord,
        name = self.name,
        firstname = self.firstname,
        lastname = self.lastname,
        dateofbirth = self.dateofbirth,
        sex = self.sex,
        height = self.height,
        money = self.money,
        bank = self.bank,
        black_money = self.black_money,
        job = self.job,
        job_grade = self.job_grade,
        gang = self.gang,
        gang_grade = self.gang_grade,
        position = self.position,
        is_dead = self.is_dead,
        group = self.group,
        metadata = self.metadata,
        status = self.status
    }
end

-- =============================================
-- SYSTÈME DE JOUEURS
-- =============================================

-- Initialiser le système
function Framework.Players:Init()
    self:RegisterEvents()
    self:LoadDefaultJobs()
    Framework.Debug.Info("Players system initialized")
end

-- Enregistrer les événements
function Framework.Players:RegisterEvents()
    -- Connexion d'un joueur
    AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
        local source = source
        local identifier = Framework.Players:GetIdentifier(source)

        deferrals.defer()
        Wait(0)
        deferrals.update('Chargement de votre profil...')

        if not identifier then
            deferrals.done('Erreur: Impossible de récupérer votre identifiant')
            return
        end

        deferrals.done()
    end)

    -- Joueur connecté
    AddEventHandler('playerJoining', function()
        local source = source
        Wait(1000) -- Attendre que le joueur soit complètement connecté
        Framework.Players:CheckOrCreatePlayer(source)
    end)

    -- Joueur déconnecté
    AddEventHandler('playerDropped', function()
        local source = source
        Framework.Players:UnloadPlayer(source)
    end)

    -- Sauvegarde automatique
    CreateThread(function()
        while true do
            Wait(300000) -- 5 minutes
            Framework.Players:SaveAllPlayers()
        end
    end)
end

-- Vérifier ou créer un joueur
function Framework.Players:CheckOrCreatePlayer(source)
    local identifier = self:GetIdentifier(source)
    if not identifier then
        Framework.Debug.Error(('No identifier found for player: %s'):format(source))
        return false
    end
    
    Framework.Database.fetchSingle('SELECT * FROM users WHERE identifier = ?', {identifier}, function(result)
        if result then
            -- Joueur existe, le charger
            Framework.Players:LoadPlayer(source, result)
        else
            -- Nouveau joueur, déclencher la création de personnage
            TriggerClientEvent('framework:client:StartCharacterCreation', source)
        end
    end)
end

-- Charger un joueur
function Framework.Players:LoadPlayer(source, userData)
    local identifier = userData.identifier
    local player = Player:new(source, identifier, userData)
    
    self.list[source] = player
    self.identifiers[identifier] = source
    
    -- Déclencher les événements
    TriggerEvent('framework:server:PlayerLoaded', source, player)
    TriggerClientEvent('framework:client:PlayerLoaded', source, player:GetData())
    
    Framework.Debug.Success(('Player loaded: %s'):format(identifier))
    return true
end

-- Décharger un joueur
function Framework.Players:UnloadPlayer(source)
    local player = self.list[source]
    if not player then return end
    
    player:Save()
    
    self.identifiers[player.identifier] = nil
    self.list[source] = nil
    
    Framework.Debug.Info(('Player unloaded: %s'):format(player.identifier))
end

-- Récupérer un joueur par source
function Framework.Players:GetPlayer(source)
    return self.list[source]
end

function Player:GetInventory()
    return self.inventory or {}
end

-- Récupérer un joueur par identifiant
function Framework.Players:GetPlayerByIdentifier(source)
    local identifier = GetPlayerIdentifier(source, 0)
    local result = Framework.Database:Query('SELECT name FROM users WHERE identifier = ?', identifier)
    print(identifier)

    if result then
        return result
    end

    return nil
end

-- Récupérer tous les joueurs
function Framework.Players:GetAllPlayers()
    return self.list
end

-- Récupérer le nombre de joueurs
function Framework.Players:GetPlayerCount()
    return Framework.Utils.TableSize(self.list)
end

-- Sauvegarder tous les joueurs
function Framework.Players:SaveAllPlayers()
    local saved = 0
    for source, player in pairs(self.list) do
        if player:Save() then
            saved = saved + 1
        end
    end
    
    Framework.Debug.Info(('Saved %d players'):format(saved))
    return saved
end

-- Récupérer l'identifiant d'un joueur
function Framework.Players:GetIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in pairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    return nil
end

-- Récupérer tous les identifiants
function Framework.Players:GetAllIdentifiers(source)
    local identifiers = GetPlayerIdentifiers(source)
    local result = {}
    
    for _, id in pairs(identifiers) do
        if string.find(id, 'license:') then
            result.license = id
        elseif string.find(id, 'steam:') then
            result.steam = id
        elseif string.find(id, 'discord:') then
            result.discord = id
        end
    end
    
    return result
end

-- Charger les métiers par défaut
function Framework.Players:LoadDefaultJobs()
    local defaultJobs = {
        {name = 'unemployed', label = 'Chômeur', whitelisted = 0},
        {name = 'police', label = 'Police', whitelisted = 1},
        {name = 'ambulance', label = 'Ambulance', whitelisted = 1},
        {name = 'mechanic', label = 'Mécanicien', whitelisted = 0}
    }
    
    for _, job in pairs(defaultJobs) do
        Framework.Database.fetchSingle('SELECT * FROM jobs WHERE name = ?', {job.name}, function(existing)
            if not existing then
                Framework.Database.execute('INSERT INTO jobs (name, label, whitelisted) VALUES (?, ?, ?)', {
                    job.name, job.label, job.whitelisted
                })
            end
        end)
    end
    
    Framework.Debug.Info('Default jobs loaded')
end

-- Fonctions globales pour compatibilité
function Framework.GetPlayer(source)
    return Framework.Players:GetPlayer(source)
end

function Framework.GetPlayerByIdentifier(identifier)
    return Framework.Players:GetPlayerByIdentifier(identifier)
end

function Framework.GetIdentifier(source)
    return Framework.Players:GetIdentifier(source)
end

print('^2[Rowden Framework]^0 Players system loaded')
