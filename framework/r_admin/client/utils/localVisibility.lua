LocalVisibility = {
    entities = {},
    thread = false
}
-- Ajoute une entité à la liste des entités visibles localement
function LocalVisibility:AddEntity(entityId, entity, options)
    if not DoesEntityExist(entity) then return false end

    options = options or {}

    self.entities[entityId] = {
        entity = entity,
        localAlpha = options.localAlpha or 200,
        enableCollision = options.enableCollision ~= false, -- à true par défaut
        makeInvincible = options.makeInvincible or false,
        freezePosition = options.freezePosition or false,
        disableGravity = options.disableGravity or false
    }

    local entityData = self.entities[entityId]

    SetEntityVisible(entity, false, false)
    SetEntityAlpha(entity, entityData.localAlpha, false)

    if not entityData.enableCollision then
        SetEntityCollision(entity, false, false)
    end

    if entityData.makeInvincible then
        SetEntityInvincible(entity, true)
    end

    if entityData.freezePosition then
        FreezeEntityPosition(entity, true)
    end

    if entityData.disableGravity and IsEntityAVehicle(entity) then
        SetVehicleGravity(entity, false)
    end

    self:StartThread()

    return true
end

-- Supprime une entité de la liste
function LocalVisibility:RemoveEntity(entityId)
    if self.entities[entityId] then
        local entityData = self.entities[entityId]

        if DoesEntityExist(entityData.entity) then
            SetEntityVisible(entityData.entity, true, false)
            ResetEntityAlpha(entityData.entity)

            if not entityData.enableCollision then
                SetEntityCollision(entityData.entity, true, true)
            end

            if entityData.makeInvincible then
                SetEntityInvincible(entityData.entity, false)
            end

            if entityData.freezePosition then
                FreezeEntityPosition(entityData.entity, false)
            end

            if entityData.disableGravity and IsEntityAVehicle(entityData.entity) then
                SetVehicleGravity(entityData.entity, true)
            end
        end

        self.entities[entityId] = nil

        if self:IsEmpty() then
            self:StopThread()
        end
    end
end

-- Met à jour les options d'une entité
function LocalVisibility:UpdateEntity(entityId, options)
    if not self.entities[entityId] then return false end

    local entityData = self.entities[entityId]

    if options.localAlpha then
        entityData.localAlpha = options.localAlpha
        SetEntityAlpha(entityData.entity, entityData.localAlpha, false)
    end

    return true
end

-- Check si la liste est vide
function LocalVisibility:IsEmpty()
    return next(self.entities) == nil
end

-- Démarre le thread de visibilité
function LocalVisibility:StartThread()
    if self.thread then return end
    self.thread = true

    Citizen.CreateThread(function()
        while self.thread do
            for entityId, entityData in pairs(self.entities) do
                if DoesEntityExist(entityData.entity) then
                    SetEntityLocallyVisible(entityData.entity)

                    if entityData.localAlpha then
                        SetEntityAlpha(entityData.entity, entityData.localAlpha, false)
                    end
                else
                    self.entities[entityId] = nil
                end
            end

            if self:IsEmpty() then
                self:StopThread()
                break
            end

            Citizen.Wait(0)
        end
    end)
end

-- Stop le thread de visibilité
function LocalVisibility:StopThread()
    self.thread = false
end

-- Supprime toutes les entités et arrête le thrad
function LocalVisibility:Clear()
    for entityId in pairs(self.entities) do
        self:RemoveEntity(entityId)
    end
    self:StopThread()
end

-- Config une entité
function LocalVisibility:SetupEntity(entityId, entity, config)
    config = config or {}

    local options = {
        localAlpha = config.alpha or 200,
        enableCollision = config.collision ~= false,
        makeInvincible = config.invincible == true,
        freezePosition = config.freeze == true,
        disableGravity = config.gravity == false
    }

    return self:AddEntity(entityId, entity, options)
end

function LocalVisibility:Debug()
    print("=== DEBUG LocalVisibility ===")
    print("Thread actif:", self.thread)
    print("Nombre d'entités:", self:CountEntities())

    for entityId, entityData in pairs(self.entities) do
        print("Entité:", entityId)
        print("  - Handle:", entityData.entity)
        print("  - Existe:", DoesEntityExist(entityData.entity))
        print("  - Visible:", IsEntityVisible(entityData.entity))
        print("  - Alpha:", entityData.localAlpha)
    end
end

function LocalVisibility:CountEntities()
    local count = 0
    for _ in pairs(self.entities) do count = count + 1 end
    return count
end
