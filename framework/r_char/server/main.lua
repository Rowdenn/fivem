local Framework = exports['framework']:GetFramework()

function GetAppearanceData(character)
    local excludedFields = {
        "firstname",
        "lastname", 
        "dateofbirth",
        "sex",
        "height"
    }
    
    local appearance = {}
    
    for key, value in pairs(character) do
        local isExcluded = false
        for _, excluded in ipairs(excludedFields) do
            if key == excluded then
                isExcluded = true
                break
            end
        end
        
        if not isExcluded then
            appearance[key] = value
        end
    end
    
    return appearance
end

RegisterServerEvent('r_char:checkCharacter')
AddEventHandler('r_char:checkCharacter', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    Framework.Database:Query('SELECT * FROM users WHERE identifier = ?', {identifier}, function(result)
        if result and #result > 0 then
            local user = result[1]
            
            if user.skin and user.skin ~= 'null' and user.skin ~= '' then
                -- Le personnage existe déjà
                local character = user.skin
                local sex = json.decode(user.sex)
                local lastPosition = nil
                
                if user.position and user.position ~= 'null' then
                    local positionData = json.decode(user.position)

                    if positionData then
                        lastPosition = {
                            x = tonumber(positionData.x),
                            y = tonumber(positionData.y),
                            z = tonumber(positionData.z)
                        }
                    end
                end

                TriggerClientEvent('r_char:loadCharacter', src, character, sex, lastPosition)
            else
                TriggerClientEvent('r_char:needCreation', src)
            end
        else
            TriggerClientEvent('r_char:needCreation', src)
        end
    end)
end)

function SavePlayerLastPosition(source)
    local player = GetPlayerPed(source)
    local coords = GetEntityCoords(player)
    local identifier = GetPlayerIdentifier(source, 0)
    local position = {
        x = coords.x,
        y = coords.y,
        z = coords.z
    }

    Framework.Database:Query('UPDATE users SET position = ? WHERE identifier = ?', {
        json.encode(position),
        identifier
    })
end

AddEventHandler('playerDropped', function()
    SavePlayerLastPosition(source)
end)

RegisterServerEvent('r_char:saveCharacter')
AddEventHandler('r_char:saveCharacter', function(character)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local playerName = GetPlayerName(src)
    local appearanceData = GetAppearanceData(character)
    
    Framework.Database:Query('INSERT INTO users (identifier, name, firstname, lastname, height, dateofbirth, sex, skin) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        identifier,
        playerName,
        character.firstname,
        character.lastname,
        character.height,
        character.dateofbirth,
        json.encode(character.sex),
        json.encode(appearanceData)
    }, function(result)
        if result then
            TriggerClientEvent('chat:addMessage', src, {
                color = {0, 255, 0},
                multiline = true,
                args = {"Système", "Personnage créé avec succès !"}
            })
        end
    end)
end)