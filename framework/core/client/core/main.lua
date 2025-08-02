local isPlayerRagdoll = false
local isRagdollForced = false

-- Fonction export pour forcer le ragdoll dans d'autres scripts
function SetForcedRagdoll(state)
    isRagdollForced = state
    if state then
        isPlayerRagdoll = false
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local player = PlayerPedId()

        -- Si le ragdoll est forcé par un autre script
        if isRagdollForced then
            if not IsPedRagdoll(player) then
                SetPedToRagdoll(player, 1000, 1000, 0, false, false, false)
            end

            if IsControlJustPressed(0, 73) then -- touche X
                isRagdollForced = false
                isPlayerRagdoll = false
                ExitRagdoll(player)
            end
            -- Si le ragdoll est voulu par le joueur
        elseif isPlayerRagdoll then
            if not IsPedRagdoll(player) then
                SetPedToRagdoll(player, 1000, 1000, 0, false, false, false)
            end

            if IsControlJustPressed(0, 73) then -- touche X
                isPlayerRagdoll = false
                ExitRagdoll(player)
            end
            -- Aucun ragdoll d'actif
        else
            if IsControlJustPressed(0, 73) then -- touche X
                isPlayerRagdoll = true
                SetPedToRagdoll(player, 1000, 1000, 0, false, false, false)
            end
        end
    end
end)

-- Permet de sortir de l'état de ragdoll
function ExitRagdoll(ped)
    TaskPlayAnim(ped, "get_up@directional@transition@prone_to_seated@crawl", "front", 8.0, -8.0, 1000, 0, 0, false, false,
        false)
end

function StartForcedRagdoll()
    isRagdollForced = true
    isPlayerRagdoll = false
end

function StopForcedRagdoll()
    isRagdollForced = false
    isPlayerRagdoll = false
    local player = PlayerPedId()
    ExitRagdoll(player)
end

function IsPlayerInRagdoll()
    return isPlayerRagdoll or isRagdollForced
end

function IsPlayerVoluntaryRagdoll()
    return isPlayerRagdoll
end

function IsPlayerForceRagdoll()
    return isRagdollForced
end

function RegisterAndHandleNetEvent(event, cb)
    RegisterNetEvent(event)
    AddEventHandler(event, cb)
end

exports('SetForcedRagdoll', SetForcedRagdoll)
exports('StartForcedRagdoll', StartForcedRagdoll)
exports('StopForceRagdoll', StopForcedRagdoll)
exports('IsPlayerInRagdoll', IsPlayerInRagdoll)
exports('IsPlayerVoluntaryRagdoll', IsPlayerVoluntaryRagdoll)
exports('IsPlayerForceRagdoll', IsPlayerForceRagdoll)
