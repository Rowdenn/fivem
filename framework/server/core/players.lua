Framework.Player = {}

function Framework.Player:GetPermissionsLevel(source)
    local identifier = GetPlayerIdentifier(source, 0)
    if not identifier then return 0 end

    local result = Framework.Database:Query("SELECT permission_level FROM users WHERE identifier = ?", {
        identifier
    })

    if result and result[1] and result[1].permission_level then
        return result[1].permission_level
    end

    return 0
end
