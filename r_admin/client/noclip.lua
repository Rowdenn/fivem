-- Config du NoClip
local NoClip = {
    enabled = false,
    inVehicle = false,
    vehicle = nil,
    localVisibilityThread = false,
    speed = {
        slow = 0.5,
        normal = 2.0,
        fast = 5.0,
        current = 2.0
    },
    keys = {
        toggle = 289, -- F2
        forward = 32, -- W
        backward = 33, -- S
        left = 34, -- A
        right = 35, -- D
        up = 44, -- Q
        down = 38, -- E
        speedUp = 21, -- Left Shift
        speedDown = 19, -- Left Alt
    }
}

-- * La fonction SetEntityLocallyVisible() a besoin d'être dans un thread car elle se base sur la frame actuelle
-- Permet de rendre le joueur visible uniquement pour lui même
function StartLocalVisibilityThread()
    if NoClip.localVisibilityThread then return end

    NoClip.localVisibilityThread = true
    Citizen.CreateThread(function()
        while NoClip.localVisibilityThread do
            if NoClip.enabled then
                local ped = PlayerPedId()

                SetEntityLocallyVisible(ped)

                if NoClip.inVehicle and DoesEntityExist(NoClip.vehicle) then
                    SetEntityLocallyVisible(NoClip.vehicle)
                end
            end

            Citizen.Wait(0)
        end
    end)
end

-- Désactive le thread pour la visibilité locale
function StopLocalVisibilityThread()
    NoClip.localVisibilityThread = false
end

-- Toggle la visibilité de l'entité qui noclip
function SetEntityVisibility(entity, visibleToOthers, localAlpha)
    if visibleToOthers then
        SetEntityVisible(entity, true, false)
        if localAlpha then
            SetEntityAlpha(entity, localAlpha, false)
        else
            ResetEntityAlpha(entity)
        end
    else
        SetEntityVisible(entity, false, false)
        SetEntityAlpha(entity, localAlpha or 150, false)
    end
end

-- Toggle le noclip
function Toggle()
    NoClip.enabled = not NoClip.enabled
    local ped = PlayerPedId()
    
    if NoClip.enabled then
        StartLocalVisibilityThread()

        if IsPedInAnyVehicle(ped, false) then
            NoClip.inVehicle = true
            NoClip.vehicle = GetVehiclePedIsIn(ped, false)

            SetEntityVisibility(NoClip.vehicle, false, 150)
            SetEntityInvincible(NoClip.vehicle, true)
            FreezeEntityPosition(NoClip.vehicle, true)
            SetEntityCollision(NoClip.vehicle, false, false)
            SetVehicleGravity(NoClip.vehicle, false)
        else
            NoClip.inVehicle = false
            NoClip.vehicle = nil
        end
        SetEntityVisibility(ped, false, 150)
        SetEntityInvincible(ped, true)

        if not NoClip.inVehicle then
            FreezeEntityPosition(ped, true)
            SetEntityCollision(ped, false, false)
        end
    else
        StopLocalVisibilityThread()

        if NoClip.inVehicle and DoesEntityExist(NoClip.vehicle) then
            SetEntityVisibility(NoClip.vehicle, true)
            SetEntityInvincible(NoClip.vehicle, false)
            FreezeEntityPosition(NoClip.vehicle, false)
            SetEntityCollision(NoClip.vehicle, true, true)
            SetVehicleGravity(NoClip.vehicle, true)
            SetEntityVelocity(NoClip.vehicle, 0.0, 0.0, 0.0)
            StartLandingCheck(NoClip.vehicle, true)
        else
            SetEntityVisibility(ped, true)
            FreezeEntityPosition(ped, false)
            SetEntityCollision(ped, true, true)
            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
            StartLandingCheck(ped, false)
        end
    
        NoClip.inVehicle = false
        NoClip.vehicle = nil
    end
end

-- Fait "tomber" l'entité à la désactivation du noclip
function StartLandingCheck(entity, isVehicle)
    Citizen.CreateThread(function()
        local checkCount = 0
        local maxChecks = 100
        
        while checkCount < maxChecks do
            Citizen.Wait(50)
            checkCount = checkCount + 1
            
            if not DoesEntityExist(entity) then
                break
            end
            
            local coords = GetEntityCoords(entity)
            local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z, coords.x, coords.y, coords.z - 2.0, -1, entity, 0)
            local _, hit, _, _, _ = GetShapeTestResult(rayHandle)
            
            if hit then
                local velocity = GetEntityVelocity(entity)
                local verticalSpeed = math.abs(velocity.z)
                
                if verticalSpeed < 0.5 then
                    if isVehicle then
                        SetEntityInvincible(entity, false)
                        local driver = GetPedInVehicleSeat(entity, -1)
                        if driver == PlayerPedId() then
                            SetEntityInvincible(PlayerPedId(), false)
                        end
                    else
                        SetEntityInvincible(entity, false)
                    end
                    break
                end
            end
        end
        
        if checkCount >= maxChecks then
            SetEntityInvincible(entity, false)
            if isVehicle then
                local driver = GetPedInVehicleSeat(entity, -1)
                if driver == PlayerPedId() then
                    SetEntityInvincible(PlayerPedId(), false)
                end
            end
        end
    end)
end

-- Mouvements du noclip
function HandleMovement()
    if not NoClip.enabled then return end
    
    local ped = PlayerPedId()
    local entity = NoClip.inVehicle and NoClip.vehicle or ped
    
    if not DoesEntityExist(entity) then return end
    
    local coords = GetEntityCoords(entity)
    
    local camHeading = GetGameplayCamRelativeHeading() + GetEntityHeading(entity)
    local camPitch = GetGameplayCamRelativePitch()
    
    local actualCamHeading = GetGameplayCamRot(2).z
    SetEntityHeading(entity, actualCamHeading)
    
    local x = -math.sin(camHeading * math.pi / 180.0)
    local y = math.cos(camHeading * math.pi / 180.0)
    local z = math.sin(camPitch * math.pi / 180.0)
    
    local len = math.sqrt(x * x + y * y + z * z)
    if len ~= 0 then
        x, y, z = x / len, y / len, z / len
    end
    
    if IsControlPressed(0, NoClip.keys.speedUp) then
        NoClip.speed.current = NoClip.speed.fast
    elseif IsControlPressed(0, NoClip.keys.speedDown) then
        NoClip.speed.current = NoClip.speed.slow
    else
        NoClip.speed.current = NoClip.speed.normal
    end
    
    local moveX, moveY, moveZ = 0.0, 0.0, 0.0
    
    if IsControlPressed(0, NoClip.keys.forward) then
        moveX = moveX + x
        moveY = moveY + y
        moveZ = moveZ + z
    end
    
    if IsControlPressed(0, NoClip.keys.backward) then
        moveX = moveX - x
        moveY = moveY - y
        moveZ = moveZ - z
    end
    
    if IsControlPressed(0, NoClip.keys.left) then
        moveX = moveX + (-y)
        moveY = moveY + x
    end
    
    if IsControlPressed(0, NoClip.keys.right) then
        moveX = moveX - (-y)
        moveY = moveY - x
    end
    
    if IsControlPressed(0, NoClip.keys.up) then
        moveZ = moveZ + 1.0
    end
    
    if IsControlPressed(0, NoClip.keys.down) then
        moveZ = moveZ - 1.0
    end
    
    local moveLen = math.sqrt(moveX * moveX + moveY * moveY + moveZ * moveZ)
    if moveLen > 0 then
        moveX, moveY, moveZ = moveX / moveLen, moveY / moveLen, moveZ / moveLen
        
        local newCoords = vector3(
            coords.x + moveX * NoClip.speed.current,
            coords.y + moveY * NoClip.speed.current,
            coords.z + moveZ * NoClip.speed.current
        )
        
        SetEntityCoordsNoOffset(entity, newCoords.x, newCoords.y, newCoords.z, true, true, true)
    end
    
    SetEntityVelocity(entity, 0.0, 0.0, 0.0)
end

-- Handle les mouvements du noclip
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        HandleMovement()
    end
end)

-- Ecoute la touche pour toggle le noclip
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if IsControlJustPressed(0, NoClip.keys.toggle) then
            Toggle()
        end
        
        if NoClip.enabled then
            DisableControlAction(0, 75, true) -- Disable exit vehicle
            DisableControlAction(27, 75, true) -- Disable exit vehicle
        end
    end
end)