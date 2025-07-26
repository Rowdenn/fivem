local previewVehicle = nil
local vehicleCategories = {}
local previewPosition = nil

local classMapping = {
    [0]  = { name = "Compacts" },
    [1]  = { name = "Sedans" },
    [2]  = { name = "SUV" },
    [3]  = { name = "Coupés" },
    [4]  = { name = "Muscle" },
    [5]  = { name = "Sports Classics" },
    [6]  = { name = "Sports" },
    [7]  = { name = "Supercars" },
    [8]  = { name = "Motos" },
    [9]  = { name = "Off-road" },
    [10] = { name = "Industriels" },
    [11] = { name = "Utilitaires" },
    [12] = { name = "Vans" },
    [13] = { name = "Vélos" },
    [14] = { name = "Bateaux" },
    [15] = { name = "Hélicoptères" },
    [16] = { name = "Avions" },
    [17] = { name = "Services" },
    [18] = { name = "Urgences" },
    [19] = { name = "Militaires" },
    [20] = { name = "Commerciaux" },
    [22] = { name = "Open Wheel" }
}

function GetVehicleDisplayName(vehicleModel)
    local modelHash = GetHashKey(vehicleModel)
    local displayName = GetDisplayNameFromVehicleModel(modelHash)
    local labelText = GetLabelText(displayName)

    if labelText == "NULL" or labelText == displayName then
        return vehicleModel:gsub("^%l", string.upper):gsub("_", " "):gsub("(%d+)$", " %1")
    end

    return labelText
end

function GenerateVehicleCategories()
    vehicleCategories = {}

    for classId, classData in pairs(classMapping) do
        vehicleCategories[classId] = {
            name = classData.name,
            class = classId,
            vehicles = {}
        }
    end

    local allVehicleModels = GetAllVehicleModels()

    for _, vehicleModel in ipairs(allVehicleModels) do
        local modelHash = GetHashKey(vehicleModel)

        if IsModelInCdimage(modelHash) and IsModelAVehicle(modelHash) then
            local vehicleClass = GetVehicleClassFromName(modelHash)

            if vehicleCategories[vehicleClass] then
                table.insert(vehicleCategories[vehicleClass].vehicles, {
                    name = GetVehicleDisplayName(vehicleModel),
                    model = vehicleModel,
                    class = vehicleClass
                })
            end
        end
    end

    for _, category in pairs(vehicleCategories) do
        table.sort(category.vehicles, function(a, b)
            return a.name < b.name
        end)
    end
end

function GetNonEmptyCategories()
    local nonEmptyCategories = {}

    for classId, category in pairs(vehicleCategories) do
        if #category.vehicles > 0 then
            table.insert(nonEmptyCategories, {
                id = classId,
                name = category.name,
                vehicles = category.vehicles,
                count = #category.vehicles
            })
        end
    end

    table.sort(nonEmptyCategories, function(a, b)
        return a.name < b.name
    end)

    return nonEmptyCategories
end

function SearchVehicles(searchTerm)
    local searchResult = {}

    if not searchTerm or searchTerm == "" or string.len(searchTerm) < 2 then
        return searchResult
    end

    searchTerm = string.lower(searchTerm)
    for _, category in pairs(vehicleCategories) do
        for _, vehicle in ipairs(category.vehicles) do
            local vehicleName = string.lower(vehicle.name)
            local vehicleModel = string.lower(vehicle.model)

            -- Recherche dans le nom ET le modèle
            if string.find(vehicleName, searchTerm, 1, true) or
                string.find(vehicleModel, searchTerm, 1, true) then
                table.insert(searchResult, {
                    name = vehicle.name,
                    model = vehicle.model,
                    class = vehicle.class,
                    categoryName = category.name,
                })
            end
        end
    end

    -- Trie les résultats par pertinence
    table.sort(searchResult, function(a, b)
        local aNameMatch = string.lower(a.name) == searchTerm
        local bNameMatch = string.lower(b.name) == searchTerm
        local aModelMatch = string.lower(a.model) == searchTerm
        local bModelMatch = string.lower(b.model) == searchTerm

        if aNameMatch and not bNameMatch then return true end
        if bNameMatch and not aNameMatch then return false end
        if aModelMatch and not bModelMatch then return true end
        if bModelMatch and not aModelMatch then return false end

        return a.name < b.name
    end)

    return searchResult
end

function StartVehiclePreview(vehicleModel)
    EndVehiclePreview()

    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Wait(0)
    end

    local player = PlayerPedId()

    if not previewPosition then
        local playerPos = GetEntityCoords(player)
        previewPosition = {
            x = playerPos.x - 3.0,
            y = playerPos.y + 5.0,
            z = playerPos.z
        }
    end

    previewVehicle = CreateVehicle(vehicleModel, previewPosition.x, previewPosition.y, previewPosition.z, 180.0, false,
        false)

    SetEntityAsMissionEntity(previewVehicle, true, true)
    SetVehicleEngineOn(previewVehicle, false, false, false)
    SetEntityCollision(previewVehicle, false, false)
    FreezeEntityPosition(previewVehicle, true)
    SetEntityAlpha(previewVehicle, 200, false)

    SetModelAsNoLongerNeeded(vehicleModel)
end

function EndVehiclePreview()
    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteVehicle(previewVehicle)
        previewVehicle = nil
    end
end

function ResetPreviewPosition()
    previewPosition = nil
end

function ShowSearchResults(searchTerm)
    local results = SearchVehicles(searchTerm)

    local searchMenu = MenuV:CreateMenu('Résultats: "' .. searchTerm .. '"', false, 'topright', 255, 0, 0, "size-125",
        'interaction_bgd', 'commonmenu', false, 'native')

    if #results == 0 then
        searchMenu:AddButton({
            label = 'Aucun résultat',
            description = 'Aucun véhicule trouvé pour "' .. searchTerm .. '"',
            select = function() end
        })
    else
        -- Afficher le nombre de résultats
        searchMenu:AddButton({
            label = #results .. ' résultat(s) trouvé(s)',
            description = 'Véhicules correspondant à votre recherche',
            select = function() end
        })

        -- Séparateur
        searchMenu:AddButton({
            label = '────────────────',
            description = '',
            select = function() end
        })

        for i, vehicle in ipairs(results) do
            searchMenu:AddButton({
                label = vehicle.name,
                description = 'Modèle: ' .. vehicle.model .. ' • Catégorie: ' .. vehicle.categoryName,
                select = function()
                    SpawnVehicleForPlayer(vehicle.model, vehicle.name)
                    EndVehiclePreview()
                    searchMenu:Close()
                end
            })
        end
    end

    searchMenu:AddButton({
        label = 'Nouvelle recherche',
        description = 'Effectuer une nouvelle recherche',
        select = function()
            EndVehiclePreview()
            searchMenu:Close()
            ShowVehicleSearch()
        end
    })

    searchMenu:On('update', function(index)
        local vehicleIndex = index - 2
        if vehicleIndex > 0 and vehicleIndex <= #results then
            local selectedVehicle = results[vehicleIndex]
            StartVehiclePreview(selectedVehicle.model)
        end
    end)

    searchMenu:On('close', function()
        EndVehiclePreview()
    end)

    searchMenu:Open()
end

function ShowVehicleSearch()
    local searchMenu = MenuV:CreateMenu('Recherche de véhicule', false, 'topright', 255, 0, 0, "size-125",
        'interaction_bgd', 'commonmenu', false, 'native')

    searchMenu:AddButton({
        label = 'Saisir la recherche',
        description = 'Tapez au moins 2 caractères pour rechercher',
        select = function()
            DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 30)

            while UpdateOnscreenKeyboard() == 0 do
                DisableAllControlActions(0)
                Wait(0)
            end

            if GetOnscreenKeyboardResult() then
                local searchTerm = GetOnscreenKeyboardResult()
                if string.len(searchTerm) >= 2 then
                    searchMenu:Close()
                    ShowSearchResults(searchTerm)
                else
                    TriggerServerEvent('r_admin:showNotification', 'Veuillez saisir au moins 2 caractères', 'error')
                end
            end
        end
    })

    searchMenu:Open()
end

function ShowVehicleCategories()
    if next(vehicleCategories) == nil then
        GenerateVehicleCategories()
    end

    local vehicleCategoryMenu = MenuV:CreateMenu('Catégories Véhicules', false, 'topright', 255, 0, 0, "size-125",
        'interaction_bgd', 'commonmenu', false, 'native')

    local nonEmptyCategories = GetNonEmptyCategories()

    vehicleCategoryMenu:AddButton({
        label = 'Rechercher un véhicule',
        description = 'Rechercher par nom ou modèle',
        select = function()
            ShowVehicleSearch()
        end
    })

    vehicleCategoryMenu:AddButton({
        label = '── Catégories ──',
        description = '',
        select = function() end
    })

    for _, category in ipairs(nonEmptyCategories) do
        vehicleCategoryMenu:AddButton({
            label = category.name,
            description = 'Voir les véhicules de type ' .. category.name .. ' (' .. category.count .. ' véhicules)',
            select = function()
                ShowVehiclesInCategory(category)
            end
        })
    end

    vehicleCategoryMenu:Open()
end

function ShowVehiclesInCategory(category)
    local vehicleMenu = MenuV:CreateMenu(category.name, false, 'topright', 255, 0, 0, "size-125", 'interaction_bgd',
        'commonmenu', false, 'native')

    for _, vehicle in ipairs(category.vehicles) do
        local vehicleButton = vehicleMenu:AddButton({
            label = vehicle.name,
            description = 'Modèle: ' .. vehicle.model,
            select = function()
                SpawnVehicleForPlayer(vehicle.model, vehicle.name)
                EndVehiclePreview()
                vehicleMenu:Close()
            end
        })

        vehicleButton:On('enter', function()
            StartVehiclePreview(vehicle.model)
        end)
    end

    vehicleMenu:On('close', function()
        EndVehiclePreview()
        ResetPreviewPosition()
    end)

    vehicleMenu:Open()
end

function SpawnVehicleForPlayer(vehicleModel, vehicleName)
    local player = PlayerPedId()
    local playerHeading = GetEntityHeading(player)
    local vehicleHash = GetHashKey(vehicleModel)

    RequestModel(vehicleHash)

    local timeout = 0
    while not HasModelLoaded(vehicleHash) and timeout < 50 do
        Citizen.Wait(100)
        timeout = timeout + 1
    end

    local spawnCoords = GetOffsetFromEntityInWorldCoords(player, 0.0, 0.0, 0.0)
    local vehicle = CreateVehicle(vehicleHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, playerHeading, true, false)

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)

    TaskWarpPedIntoVehicle(player, vehicle, -1)

    SetModelAsNoLongerNeeded(vehicleHash)

    TriggerServerEvent('r_admin:showNotification', vehicleName .. ' spawn avec succès', 'success')
end

CreateThread(function()
    Wait(2000)
    GenerateVehicleCategories()
end)
