local currentWheelCategory = 0
local currentVehicle = nil
local isDriver = false

-- C'EST UN ENFER PAR PITIE ACHEVEZ MOI

-- Types de jantes
local wheelTypes = {
    [0]  = "Sport",
    [1]  = "Muscle",
    [2]  = "Lowrider",
    [3]  = "SUV",
    [4]  = "Offroad",
    [5]  = "Tuner",
    [6]  = "Bike Wheels",
    [7]  = "High End",
    [8]  = "Benny's Original",
    [9]  = "Benny's Bespoke",
    [10] = "Formula",
    [11] = "Street",
    [12] = "Track"
}

-- Catégories de modifications
local modCategories = {
    [0]  = "Spoilers",
    [1]  = "Pare-chocs avant",
    [2]  = "Pare-chocs arrière",
    [3]  = "Bas de caisse",
    [4]  = "Échappement",
    [5]  = "Châssis",
    [6]  = "Calandre",
    [7]  = "Capot",
    [8]  = "Garde-boue",
    [9]  = "Garde-boue droite",
    [10] = "Toit",
    [11] = "Moteur",
    [12] = "Frein",
    [13] = "Transmission",
    [14] = "Klaxon",
    [15] = "Suspension",
    [16] = "Blindage",
    [25] = "Plaque d'immatriculation",
    [27] = "Garniture intérieure",
    [28] = "Ornements",
    [29] = "Tableau de bord",
    [30] = "Cadran",
    [31] = "Haut-parleur de porte",
    [32] = "Sièges",
    [33] = "Volant",
    [34] = "Levier de vitesse",
    [35] = "Plaque personnalisée",
    [36] = "Haut-parleur arrière",
    [37] = "Coffre",
    [38] = "Hydrolique",
    [39] = "Kit de moteur",
    [40] = "Filtre à air",
    [41] = "Entretoises",
    [42] = "Couvre-soupape",
    [43] = "Livery",
    [44] = "Plaque latérale",
    [45] = "Échappement arrière",
    [46] = "Ventilateur",
    [47] = "Réservoir"
}

local neonColors = {
    { label = "Blanc",           r = 222, g = 222, b = 255 },
    { label = "Bleu",            r = 2,   g = 21,  b = 255 },
    { label = "Bleu électrique", r = 3,   g = 83,  b = 255 },
    { label = "Vert menthe",     r = 0,   g = 255, b = 140 },
    { label = "Vert lime",       r = 94,  g = 255, b = 1 },
    { label = "Jaune",           r = 255, g = 255, b = 0 },
    { label = "Doré",            r = 255, g = 150, b = 0 },
    { label = "Orange",          r = 255, g = 62,  b = 0 },
    { label = "Rouge",           r = 255, g = 1,   b = 1 },
    { label = "Rose poney",      r = 255, g = 50,  b = 100 },
    { label = "Rose vif",        r = 255, g = 5,   b = 190 },
    { label = "Violet",          r = 35,  g = 1,   b = 255 },
    { label = "Blacklight",      r = 15,  g = 3,   b = 255 }
}

-- TODO Changer les tableaux ci dessous pour la cohérence du code
local hornTypes = {
    [-1] = "Stock",
    [0]  = "Truck Horn",
    [1]  = "Cop Horn",
    [2]  = "Clown Horn",
    [3]  = "Musical Horn 1",
    [4]  = "Musical Horn 2",
    [5]  = "Musical Horn 3",
    [6]  = "Musical Horn 4",
    [7]  = "Musical Horn 5",
    [8]  = "Sad Trombone",
    [9]  = "Classical Horn 1",
    [10] = "Classical Horn 2",
    [11] = "Classical Horn 3",
    [12] = "Classical Horn 4",
    [13] = "Classical Horn 5",
    [14] = "Classical Horn 6",
    [15] = "Classical Horn 7",
    [16] = "Scale - Do",
    [17] = "Scale - Re",
    [18] = "Scale - Mi",
    [19] = "Scale - Fa",
    [20] = "Scale - Sol",
    [21] = "Scale - La",
    [22] = "Scale - Ti",
    [23] = "Scale - Do (High)",
    [24] = "Jazz Horn 1",
    [25] = "Jazz Horn 2",
    [26] = "Jazz Horn 3",
    [27] = "Jazz Horn Loop",
    [28] = "Star Spangled Banner 1",
    [29] = "Star Spangled Banner 2",
    [30] = "Star Spangled Banner 3",
    [31] = "Star Spangled Banner 4",
    [32] = "Classical Loop 1",
    [33] = "Classical 8",
    [34] = "Classical Loop 2"
}

local plateTypes = {
    [0] = "Bleue sur blanc 1",
    [1] = "Bleue sur blanc 2",
    [2] = "Bleue sur blanc 3",
    [3] = "Jaune sur noir",
    [4] = "Jaune sur bleu",
    [5] = "Yanks"
}

function OpenVehicleModificationMenu()
    if CurrentVehicle == nil then return end

    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player)

    CurrentVehicle = vehicle

    local vehicleModsMenu = MenuV:CreateMenu("Modifier véhicule", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    vehicleModsMenu:AddButton({
        icon = '🎨',
        label = 'Couleurs',
        description = 'Changer les couleurs du véhicule',
        select = function()
            OpenColorsMenu()
        end
    })

    vehicleModsMenu:AddButton({
        icon = '⭕',
        label = 'Jantes',
        description = 'Modifier les jantes',
        select = function()
            OpenWheelsMenu()
        end
    })

    vehicleModsMenu:AddButton({
        icon = '🔧',
        label = 'Modifications',
        description = 'Modifier les pièces du véhicule',
        select = function()
            -- OpenModsMenu()
        end
    })

    vehicleModsMenu:AddButton({
        icon = '🚗',
        label = 'Performance',
        description = 'Améliorer les performances',
        select = function()
            -- OpenPerformanceMenu()
        end
    })

    vehicleModsMenu:AddButton({
        icon = '🎵',
        label = 'Klaxon',
        description = 'Changer le klaxon',
        select = function()
            OpenHornMenu()
        end
    })

    vehicleModsMenu:AddButton({
        icon = '🔢',
        label = 'Plaque d\'immatriculation',
        description = 'Personnaliser la plaque',
        select = function()
            OpenLicensePlateMenu()
        end
    })

    vehicleModsMenu:AddButton({
        icon = '💡',
        label = 'Néons',
        description = 'Ajouter des néons',
        select = function()
            OpenNeonMenu()
        end
    })

    vehicleModsMenu:Open()
end

function OpenColorsMenu()
    if CurrentVehicle == nil then return end

    local colorMenu = MenuV:CreateMenu("Couleurs", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    colorMenu:AddButton({
        icon = '🎨',
        label = 'Couleur primaire',
        description = 'Changer la couleur principale',
        select = function()
            OpenColorSelectionMenu('primary')
        end
    })

    colorMenu:AddButton({
        icon = '🎨',
        label = 'Couleur secondaire',
        description = 'Changer la couleur secondaire',
        select = function()
            OpenColorSelectionMenu('secondary')
        end
    })

    colorMenu:Open()
end

function ChangeVehicleColor(menu, label, colorType, section)
    local sliderValues = {}
    local colorConfig

    if colorType == 'standard' then
        colorConfig = AdminConfig.StandardCarColors
    elseif colorType == 'matte' then
        colorConfig = AdminConfig.MatCarColors
    elseif colorType == 'metallic' then
        colorConfig = AdminConfig.MetalicCarColors
    end

    for colorId, colorName in pairs(colorConfig) do
        table.insert(sliderValues, {
            label = colorName,
            value = colorId
        })
    end

    table.sort(sliderValues, function(a, b) return a.value < b.value end)

    local standardColorSlider = menu:AddSlider({
        label = label,
        value = 1,
        values = sliderValues
    })

    standardColorSlider:On('change', function(uuid, key, currentValue, oldValue)
        if currentValue and type(currentValue) == "number" and sliderValues[currentValue] then
            local colorId = sliderValues[currentValue].value
            local colorName = sliderValues[currentValue].label

            ApplyVehicleColor(section, colorId)
        end
    end)
end

function OpenColorSelectionMenu(colorType)
    local colorSelMenu = MenuV:CreateMenu("Sélection couleur", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    ChangeVehicleColor(colorSelMenu, 'Standard', 'standard', colorType)
    ChangeVehicleColor(colorSelMenu, 'Matte', 'matte', colorType)
    ChangeVehicleColor(colorSelMenu, 'Metalique', 'metallic', colorType)

    colorSelMenu:Open()
end

function OpenWheelsMenu()
    local wheelsMenu = MenuV:CreateMenu("Jantes", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    if CurrentVehicle == nil then return end

    wheelsMenu:AddButton({
        label = 'Type de jantes',
        description = 'Changer le type de jantes',
        select = function()
            OpenWheelTypeMenu()
        end
    })

    wheelsMenu:AddButton({
        label = 'Couleur jantes',
        description = 'Changer la couleur des jantes',
        select = function()
            OpenWheelColorMenu()
        end
    })

    local customWheels = wheelsMenu:AddCheckbox({
        label = 'Jantes personnalisées',
        description = 'Activer/désactiver jantes custom',
        value = false,
    })

    customWheels:On('update', function(item, wasChecked, isChecked)
        local isCustom = GetVehicleModVariation(CurrentVehicle, 23)
        SetVehicleMod(CurrentVehicle, 23, GetVehicleMod(CurrentVehicle, 23), not isCustom)
        SaveVehicleMods()
    end)

    wheelsMenu:Open()
end

function OpenWheelTypeMenu()
    local wheelTypeMenu = MenuV:CreateMenu("Type de jantes", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    if CurrentVehicle == nil then return end

    local originalWheelType = GetVehicleWheelType(CurrentVehicle)
    local originalWheelMod = GetVehicleMod(CurrentVehicle, 23)


    local availableWheelTypes = {}
    for wheelTypeId, wheelTypeName in pairs(wheelTypes) do
        SetVehicleWheelType(CurrentVehicle, wheelTypeId)
        local wheelCount = GetNumVehicleMods(CurrentVehicle, 23)

        if wheelCount > 0 then
            table.insert(availableWheelTypes, {
                label = wheelTypeName .. " (" .. wheelCount .. " jantes)",
                value = wheelTypeId,
                wheelCount = wheelCount
            })
        end
    end

    SetVehicleWheelType(CurrentVehicle, originalWheelType)
    SetVehicleMod(CurrentVehicle, 23, originalWheelMod, false)

    table.sort(availableWheelTypes, function(a, b)
        return tonumber(a.value) < tonumber(b.value)
    end)

    local initialCategoryIndex = 1
    currentWheelCategory = currentWheelCategory or originalWheelType

    for i, categoryData in ipairs(availableWheelTypes) do
        if tonumber(categoryData.value) == tonumber(currentWheelCategory) then
            initialCategoryIndex = i
            break
        end
    end

    if not availableWheelTypes[initialCategoryIndex] then
        initialCategoryIndex = 1
    end

    -- Slider des catégories
    local wheelCat = wheelTypeMenu:AddSlider({
        label = "Categorie de jantes",
        value = initialCategoryIndex,
        values = availableWheelTypes
    })

    local selectedCategory = availableWheelTypes[initialCategoryIndex]
    if not selectedCategory then
        wheelTypeMenu:Close()
        return
    end

    SetVehicleWheelType(CurrentVehicle, selectedCategory.value)
    currentWheelCategory = selectedCategory.value

    local wheelOptions = { { label = "Stock", value = -1 } }
    for i = 0, selectedCategory.wheelCount - 1 do
        table.insert(wheelOptions, {
            label = "Jante #" .. (i + 1),
            value = i
        })
    end

    local currentWheelMod = GetVehicleMod(CurrentVehicle, 23)
    local initialWheelIndex = 1

    for i, option in ipairs(wheelOptions) do
        if option.value == currentWheelMod then
            initialWheelIndex = i
            break
        end
    end

    -- Slider des jantes
    local wheelSlider = wheelTypeMenu:AddSlider({
        label = "Jantes",
        value = initialWheelIndex,
        values = wheelOptions
    })

    wheelCat:On('change', function(uuid, key, currentValue, oldValue)
        if currentValue and availableWheelTypes[currentValue] then
            local newCategory = availableWheelTypes[currentValue]

            currentWheelCategory = newCategory.value
            SetVehicleWheelType(CurrentVehicle, newCategory.value)

            RemoveVehicleMod(CurrentVehicle, 23)
            SetVehicleModKit(CurrentVehicle, 0)

            SaveVehicleMods()

            -- On doit "recharger" le menu à chaque changement de catégorie parce que MenuV ne prend pas en charge les changements dynamiques ^^ (^^)
            wheelTypeMenu:Close()
            OpenWheelTypeMenu()
        end
    end)

    wheelSlider:On('change', function(uuid, key, currentValue, oldValue)
        if currentValue and wheelOptions[currentValue] then
            local wheelData = wheelOptions[currentValue]
            local wheelId = wheelData.value

            if not IsVehicleDriveable(CurrentVehicle, false) then
                return
            end

            local maxWheelIndex = GetNumVehicleMods(CurrentVehicle, 23) - 1

            if wheelId ~= -1 and wheelId > maxWheelIndex then
                return
            end

            SetVehicleWheelType(CurrentVehicle, currentWheelCategory)

            if wheelId == -1 then
                RemoveVehicleMod(CurrentVehicle, 23)
            else
                SetVehicleMod(CurrentVehicle, 23, wheelId, false)
            end

            SetVehicleModKit(CurrentVehicle, 0)
            SaveVehicleMods()
        end
    end)

    wheelTypeMenu:Open()
end

function OpenWheelColorMenu()
    local wheelMenu = MenuV:CreateMenu("Couleur Jantes", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    if CurrentVehicle == nil then return end

    local _, currentWheelColor = GetVehicleExtraColours(CurrentVehicle)

    local colorOptions = {}
    for colorId, colorName in pairs(AdminConfig.StandardCarColors) do
        table.insert(colorOptions, {
            label = colorName,
            value = colorId
        })
    end

    table.sort(colorOptions, function(a, b)
        return tonumber(a.value) < tonumber(b.value)
    end)

    local initialColorIndex = 1
    for _, colorData in ipairs(colorOptions) do
        if tonumber(colorData.value) == tonumber(currentWheelColor) then
            initialColorIndex = 1
            break
        end
    end

    local wheelSlider = wheelMenu:AddSlider({
        label = "Couleur des jantes",
        value = initialColorIndex,
        values = colorOptions
    })

    wheelSlider:On('change', function(uuid, key, currentValue, oldValue)
        if currentValue and colorOptions[currentValue] then
            local colorData = colorOptions[currentValue]
            local colorId = colorData.value

            local primaryColor, _ = GetVehicleExtraColours(CurrentVehicle)
            SetVehicleExtraColours(CurrentVehicle, primaryColor, colorId)

            SaveVehicleMods()
        end
    end)

    wheelMenu:Open()
end

function OpenHornMenu()
    local hornMenu = MenuV:CreateMenu("Klaxon", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    if CurrentVehicle == nil then return end

    for hornId = -1, 34 do
        if hornTypes[hornId] then
            hornMenu:AddButton({
                label = hornTypes[hornId],
                description = 'Ajouter le klaxon ' .. hornTypes[hornId] .. 'au véhicule',
                select = function()
                    print("Setting horn:", hornId, hornTypes[hornId])
                    SetVehicleMod(CurrentVehicle, 14, hornId, false)
                    SetVehicleModKit(CurrentVehicle, 0)
                    SaveVehicleMods()
                end
            })
        end
    end

    hornMenu:Open()
end

function OpenLicensePlateMenu()
    local plateMenu = MenuV:CreateMenu("Plaque", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    if CurrentVehicle == nil then return end

    plateMenu:AddButton({
        label = 'Texte personnalisé',
        description = 'Changer le texte de la plaque',
        select = function()
            DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 8)
            while UpdateOnscreenKeyboard() == 0 do
                DisableAllControlActions(0)
                Wait(0)
            end
            if GetOnscreenKeyboardResult() then
                local plateText = GetOnscreenKeyboardResult()
                SetVehicleNumberPlateText(CurrentVehicle, plateText)
                SaveVehicleMods()
                TriggerServerEvent('r_admin:client:showNotification', 'Plaque changée: ' .. plateText, 'success')
            end
        end
    })

    local currentLicensePlate = GetVehicleNumberPlateTextIndex(CurrentVehicle)

    local licensePlateOptions = {}
    for plateId, plateName in pairs(plateTypes) do
        table.insert(licensePlateOptions, {
            label = plateName,
            value = plateId
        })
    end

    local initialPlateIndex = 1
    for i, plateData in ipairs(licensePlateOptions) do
        if tonumber(plateData.value) == tonumber(currentLicensePlate) then
            initialPlateIndex = i
            break
        end
    end

    local plateSlider = plateMenu:AddSlider({
        label = "Type de plaque",
        value = initialPlateIndex,
        values = licensePlateOptions
    })

    plateSlider:On('change', function(uuid, key, currentValue, oldValue)
        if currentValue and licensePlateOptions[currentValue] then
            local plateData = licensePlateOptions[currentValue]
            local plateId   = plateData.value

            SetVehicleNumberPlateTextIndex(CurrentVehicle, plateId)
            SetVehicleModKit(CurrentVehicle, 0)
            SaveVehicleMods()
        end
    end)

    plateMenu:Open()
end

function OpenNeonMenu()
    local neonMenu = MenuV:CreateMenu("Néons", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    if CurrentVehicle == nil then return end

    neonMenu:AddButton({
        label = 'Activer/Désactiver néons',
        description = 'Allumer ou éteindre tous les néons',
        select = function()
            local isEnabled = IsVehicleNeonLightEnabled(CurrentVehicle, 0) or
                IsVehicleNeonLightEnabled(CurrentVehicle, 1) or
                IsVehicleNeonLightEnabled(CurrentVehicle, 2) or
                IsVehicleNeonLightEnabled(CurrentVehicle, 3)

            for i = 0, 3 do
                SetVehicleNeonLightEnabled(CurrentVehicle, i, not isEnabled)
            end

            TriggerServerEvent('r_admin:client:showNotification',
                isEnabled and 'Néons désactivés' or 'Néons activés', 'info')
        end
    })

    neonMenu:AddButton({
        label = 'Couleur des néons',
        description = 'Changer la couleur des néons',
        select = function()
            OpenNeonColorMenu()
        end
    })

    local neonPositions = {
        { id = 0, name = "Gauche" }, { id = 1, name = "Droite" },
        { id = 2, name = "Avant" }, { id = 3, name = "Arrière" }
    }

    neonMenu:AddButton({
        label = '── Positions individuelles ──',
        description = '',
        select = function() end
    })

    for _, pos in ipairs(neonPositions) do
        neonMenu:AddButton({
            label = 'Néon ' .. pos.name,
            description = 'Activer/désactiver néon ' .. pos.name,
            select = function()
                local isEnabled = IsVehicleNeonLightEnabled(CurrentVehicle, pos.id)
                SetVehicleNeonLightEnabled(CurrentVehicle, pos.id, not isEnabled)
                SaveVehicleMods()
            end
        })
    end

    neonMenu:Open()
end

function OpenNeonColorMenu()
    local neonColorMenu = MenuV:CreateMenu("Couleur néons", false, "topright", 255, 0, 0,
        "size-125", 'interaction_bgd', 'commonmenu', false, 'native')

    if CurrentVehicle == nil then return end

    local redCurrentNeonColor, greendCurrentNeonColor, blueCurrentNeonColor = GetVehicleNeonLightsColour(CurrentVehicle)

    local initialNeonColorIndex = 1
    for _, colorData in pairs(neonColors) do
        if (tonumber(colorData.r) + tonumber(colorData.g) + tonumber(colorData.b) == redCurrentNeonColor + greendCurrentNeonColor + blueCurrentNeonColor) then
            initialNeonColorIndex = 1
            break
        end
    end

    local neonColorSlider = neonColorMenu:AddSlider({
        label = "Couleur des neons",
        value = initialNeonColorIndex,
        values = neonColors
    })

    neonColorSlider:On('change', function(uuid, key, currentValue, oldValue)
        if currentValue and neonColors[currentValue] then
            local colorData = neonColors[currentValue]
            local colorR = colorData.r
            local colorG = colorData.g
            local colorB = colorData.b

            SetVehicleNeonLightsColour(CurrentVehicle, colorR, colorG, colorB)
            SaveVehicleMods()
        end
    end)

    neonColorMenu:Open()
end

function ApplyVehicleColor(colorType, colorId)
    if CurrentVehicle ~= nil then
        if colorType == 'primary' then
            local _, primary = GetVehicleColours(CurrentVehicle)
            SetVehicleColours(CurrentVehicle, colorId, primary)
        elseif colorType == 'secondary' then
            local secondary, _ = GetVehicleColours(CurrentVehicle)
            SetVehicleColours(CurrentVehicle, secondary, colorId)
        elseif colorType == 'wheels' then
            local wheels, _ = GetVehicleExtraColours(CurrentVehicle)
            SetVehicleExtraColours(CurrentVehicle, wheels, colorId)
        end

        SaveVehicleMods()
    else
        TriggerServerEvent('r_admin:client:showNotification', 'Aucun véhicule détecté', 'error')
    end
end

function SaveVehicleMods()
    -- Fonction vide temporairement
end

function GetVehicleDetails()
    if CurrentVehicle ~= nil then
        local details = {
            name = GetDisplayNameFromVehicleModel(GetEntityModel(CurrentVehicle)),
            plate = GetVehicleNumberPlateText(CurrentVehicle),
            health = GetEntityHealth(CurrentVehicle),
            bodyHealth = GetVehicleBodyHealth(CurrentVehicle),
            engineHealth = GetVehicleEngineHealth(CurrentVehicle),
            dirtLevel = GetVehicleDirtLevel(CurrentVehicle),
            fuelLevel = GetVehicleFuelLevel(CurrentVehicle)
        }

        local info = string.format(
            "Modèle: %s\nPlaque: %s\nVie: %d/%d\nCarrosserie: %.0f%%\nMoteur: %.0f%%\nSaleté: %.1f\nCarburant: %.0f%%",
            details.name, details.plate, details.health, 1000,
            (details.bodyHealth / 1000) * 100, (details.engineHealth / 1000) * 100,
            details.dirtLevel, details.fuelLevel
        )

        TriggerServerEvent('r_admin:client:showNotification', info, 'info')
    else
        TriggerServerEvent('r_admin:client:showNotification', 'Aucun véhicule détecté', 'error')
    end
end

function ClearVehicle()
    if CurrentVehicle ~= nil then
        SetVehicleDirtLevel(CurrentVehicle, 0.0)
        WashDecalsFromVehicle(CurrentVehicle, 1.0)
        TriggerServerEvent('r_admin:client:showNotification', 'Véhicule nettoyé!', 'success')
    else
        TriggerServerEvent('r_admin:client:showNotification', 'Aucun véhicule à nettoyer', 'error')
    end
end

function RepairVehicle()
    if CurrentVehicle ~= nil then
        SetVehicleFixed(CurrentVehicle)
        SetVehicleEngineHealth(CurrentVehicle, 1000.0)
        SetVehicleBodyHealth(CurrentVehicle, 1000.0)
        SetVehiclePetrolTankHealth(CurrentVehicle, 1000.0)

        for i = 0, 7 do
            FixVehicleWindow(CurrentVehicle, i)
        end

        for i = 0, 7 do
            SetVehicleTyreFixed(CurrentVehicle, i)
        end

        TriggerServerEvent('r_admin:client:showNotification', 'Véhicule réparé avec succès', 'success')
    else
        TriggerServerEvent('r_admin:client:showNotification', 'Aucun véhicule à réparer', 'error')
    end
end

-- Boucle pour check si le joueur est dans un véhicule, pas le plus opti imo
-- TODO Optimiser la détection de la sortie d'un véhicule
Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)

        if vehicle ~= 0 then
            if GetPedInVehicleSeat(vehicle, -1) == playerPed then
                if CurrentVehicle ~= vehicle then
                    CurrentVehicle = vehicle
                    isDriver = true
                end
            else
                if isDriver then
                    CurrentVehicle = nil
                    isDriver = false
                end
            end
        else
            if CurrentVehicle then
                CurrentVehicle = nil
                isDriver = false
            end
        end

        Citizen.Wait(vehicle ~= 0 and 250 or 1000)
    end
end)
