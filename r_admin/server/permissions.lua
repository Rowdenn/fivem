local Framework = exports['framework']:GetFramework()
local playerPermissions = {}

RegisterServerEvent('r_admin:getPermissionLevel')
AddEventHandler('r_admin:getPermissionLevel', function()
    local player = source
    local permissionLevel = Framework.Player:GetPermissionsLevel(player)

    TriggerClientEvent('r_admin:receivePermissionLevel', player, permissionLevel)
end)

RegisterServerEvent('r_admin:checkPermissions')
AddEventHandler('r_admin:checkPermissions', function()
    local player = source
    local permissionLevel = Framework.Player:GetPermissionsLevel(player)
    print("Le niveau de privilège du joueur est: ", permissionLevel)

    if permissionLevel >= 1 then
        TriggerClientEvent('r_admin:openMenu', player, permissionLevel)
    else
        exports['r_notify']:ShowNotificationToPlayer(player, {
            message = "Vous n'avez pas accès à ce menu",
            type = "error",
            duration = 5000
        })
    end
end)

-- Nettoie le cache à la déconnexion d'un joueur
AddEventHandler('playerDropped', function()
    local source = source
    if source ~= nil then
        if playerPermissions[source] then
            playerPermissions[source] = nil
        end
    end
end)

-- Rafraichi les permissions d'un joueur
RegisterNetEvent('r_admin:refreshPermissions')
AddEventHandler('r_admin:refreshPermissions', function()
    local source = source
    if source ~= nil then
        playerPermissions[source] = nil
    end
end)
