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

function Framework.Player:GetFullname(source, cb)
    local identifier = GetPlayerIdentifier(source, 0)
    if not identifier then return 0 end

    Framework.Database:QuerySingle("SELECT firstname, lastname FROM users WHERE identifer = ?", { identifier },
        function(result)
            if result then
                cb({
                    identifier = identifier,
                    firstname = result.firstname,
                    lastname = result.lastname,
                    fullname = result.firstname .. ' ' .. result.lastname
                })
            else
                cb(nil)
            end
        end)



    return nil
end
