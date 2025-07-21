Framework.Vehicles = {
    spawned = {},
    owned = {},
    shops = {},
    garages = {},
    impounds = {},
    keys = {},
    maxFuel = 100.0,
    fuelDecayRate = 0.1 -- Par minute
}

-- Initialisation du système de véhicules
function Framework.Vehicles:Init()
    self:LoadVehicleData()
    self:LoadGarages()
    self:LoadShops()
    self:StartFuelSystem()
    Framework.Debug:Info('Vehicles system initialized')
end

-- Charger les données des véhicules
function Framework.Vehicles:LoadVehicleData()
    local vehicles = Framework.Database:Query('SELECT * FROM vehicles')
    
    if vehicles then
        for _, vehicle in pairs(vehicles) do
            self.owned[vehicle.plate] = {
                plate = vehicle.plate,
                owner = vehicle.owner,
                model = vehicle.model,
                props = json.decode(vehicle.props),
                garage = vehicle.garage,
                impound = vehicle.impound == 1,
                fuel = vehicle.fuel or 100.0,
                engine = vehicle.engine or 1000.0,
                body = vehicle.body or 1000.0,
                mileage = vehicle.mileage or 0,
                lastUsed = vehicle.lastUsed
            }
        end
    end
    
    Framework.Debug:Info(('Loaded %d owned vehicles'):format(Framework.Utils:TableSize(self.owned)))
end

-- Charger les garages
function Framework.Vehicles:LoadGarages()
    local garages = Framework.Database:Query('SELECT * FROM garages')
    
    if garages then
        for _, garage in pairs(garages) do
            self.garages[garage.name] = {
                name = garage.name,
                label = garage.label,
                coords = json.decode(garage.coords),
                spawn = json.decode(garage.spawn),
                type = garage.type,
                job = garage.job,
                jobGrade = garage.jobGrade or 0,
                price = garage.price or 0,
                blip = garage.blip and json.decode(garage.blip) or nil
            }
        end
    end
    
    Framework.Debug:Info(('Loaded %d garages'):format(Framework.Utils:TableSize(self.garages)))
end

-- Charger les concessionnaires
function Framework.Vehicles:LoadShops()
    local shops = Framework.Database:Query('SELECT * FROM vehicle_shops')
    
    if shops then
        for _, shop in pairs(shops) do
            self.shops[shop.name] = {
                name = shop.name,
                label = shop.label,
                coords = json.decode(shop.coords),
                vehicles = json.decode(shop.vehicles),
                type = shop.type,
                blip = shop.blip and json.decode(shop.blip) or nil
            }
        end
    end
    
    Framework.Debug:Info(('Loaded %d vehicle shops'):format(Framework.Utils:TableSize(self.shops)))
end

-- Faire apparaître un véhicule
function Framework.Vehicles:SpawnVehicle(source, model, coords, heading, plate, props)
    local playerPed = GetPlayerPed(source)
    
    if not coords then
        coords = GetEntityCoords(playerPed)
    end
    
    if not heading then
        heading = GetEntityHeading(playerPed)
    end
    
    if not plate then
        plate = self:GeneratePlate()
    end
    
    -- Vérifier si le modèle existe
    if not IsModelInCdimage(model) then
        Framework.Debug:Error(('Vehicle model %s not found'):format(model))
        return false
    end
    
    -- Créer le véhicule
    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, true)
    
    if not vehicle or vehicle == 0 then
        Framework.Debug:Error('Failed to create vehicle')
        return false
    end
    
    -- Attendre que le véhicule soit créé
    while not DoesEntityExist(vehicle) do
        Wait(50)
    end
    
    -- Configurer la plaque
    SetVehicleNumberPlateText(vehicle, plate)
    
    -- Appliquer les propriétés si fournies
    if props then
        self:SetVehicleProperties(vehicle, props)
    end
    
    -- Ajouter à la liste des véhicules générés
    self.spawned[vehicle] = {
        entity = vehicle,
        plate = plate,
        model = model,
        owner = source,
        spawned = os.time(),
        coords = coords,
        heading = heading
    }
    
    -- Donner les clés au joueur
    self:GiveKeys(source, plate)
    
    Framework.Debug:Info(('Vehicle spawned: %s (Plate: %s)'):format(model, plate))
    
    return vehicle
end

-- Supprimer un véhicule
function Framework.Vehicles:DeleteVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    
    -- Supprimer de la liste
    self.spawned[vehicle] = nil
    
    -- Supprimer l'entité
    DeleteEntity(vehicle)
    
    Framework.Debug:Info(('Vehicle deleted: %s'):format(plate))
    
    return true
end

-- Obtenir les propriétés d'un véhicule
function Framework.Vehicles:GetVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then return {} end
    
    local props = {}
    
    props.model = GetEntityModel(vehicle)
    props.plate = GetVehicleNumberPlateText(vehicle)
    props.plateIndex = GetVehicleNumberPlateTextIndex(vehicle)
    props.bodyHealth = GetVehicleBodyHealth(vehicle)
    props.engineHealth = GetVehicleEngineHealth(vehicle)
    props.fuelLevel = GetVehicleFuelLevel(vehicle)
    props.dirtLevel = GetVehicleDirtLevel(vehicle)
    props.color1 = GetVehicleColour(vehicle)
    props.color2 = GetVehicleColour(vehicle)
    props.pearlescentColor = GetVehicleExtraColours(vehicle)
    props.wheelColor = GetVehicleExtraColours(vehicle)
    props.wheels = GetVehicleWheelType(vehicle)
    props.windowTint = GetVehicleWindowTint(vehicle)
    props.xenonColor = GetVehicleXenonLightsColour(vehicle)
    
    -- Néons
    props.neonEnabled = {
        IsVehicleNeonLightEnabled(vehicle, 0),
        IsVehicleNeonLightEnabled(vehicle, 1),
        IsVehicleNeonLightEnabled(vehicle, 2),
        IsVehicleNeonLightEnabled(vehicle, 3)
    }
    
    props.neonColor = table.pack(GetVehicleNeonLightsColour(vehicle))
    props.extras = {}
    props.tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicle))
    
    -- Modifica[...]props.windowTint)
    
    if props.xenonColor then
        SetVehicleXenonLightsColour(vehicle, props.xenonColor)
    end
    
    -- Néons
    if props.neonEnabled then
        for i = 1, 4 do
            SetVehicleNeonLightEnabled(vehicle, i - 1, props.neonEnabled[i])
        end
    end
    
    if props.neonColor then
        SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
    end
    
    -- Extras
    if props.extras then
        for extraId, enabled in pairs(props.extras) do
            SetVehicleExtra(vehicle, extraId, enabled and 0 or 1)
        end
    end
    
    -- Fumée des pneus
    if props.tyreSmokeColor then
        SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
    end
    
    -- Modifications
    if props.modEngine then
        SetVehicleMod(vehicle, 11, props.modEngine, false)
    end
    
    if props.modBrakes then
        SetVehicleMod(vehicle, 12, props.modBrakes, false)
    end
    
    if props.modTransmission then
        SetVehicleMod(vehicle, 13, props.modTransmission, false)
    end
    
    if props.modSuspension then
        SetVehicleMod(vehicle, 15, props.modSuspension, false)
    end
    
    if props.modArmor then
        SetVehicleMod(vehicle, 16, props.modArmor, false)
    end
    
    if props.modTurbo then
        ToggleVehicleMod(vehicle, 18, props.modTurbo)
    end
    
    if props.modXenon then
        ToggleVehicleMod(vehicle, 22, props.modXenon)
    end
    
    if props.modFrontWheels then
        SetVehicleMod(vehicle, 23, props.modFrontWheels, false)
    end
    
    if props.modBackWheels then
        SetVehicleMod(vehicle, 24, props.modBackWheels, false)
    end
    
    if props.modPlateHolder then
        SetVehicleMod(vehicle, 25, props.modPlateHolder, false)
    end
    
    if props.modVanityPlate then
        SetVehicleMod(vehicle, 26, props.modVanityPlate, false)
    end
    
    if props.modTrimA then
        SetVehicleMod(vehicle, 27, props.modTrimA, false)
    end
    
    if props.modOrnaments then
        SetVehicleMod(vehicle, 28, props.modOrnaments, false)
    end
    
    if props.modDashboard then
        SetVehicleMod(vehicle, 29, props.modDashboard, false)
    end
    
    if props.modDial then
        SetVehicleMod(vehicle, 30, props.modDial, false)
    end
    
    if props.modDoorSpeaker then
        SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false)
    end
    
    if props.modSeats then
        SetVehicleMod(vehicle, 32, props.modSeats, false)
    end
    
    if props.modSteeringWheel then
        SetVehicleMod(vehicle, 33, props.modSteeringWheel, false)
    end
    
    if props.modShifterLeavers then
        SetVehicleMod(vehicle, 34, props.modShifterLeavers, false)
    end
    
    if props.modAPlate then
        SetVehicleMod(vehicle, 35, props.modAPlate, false)
    end
    
    if props.modSpeakers then
        SetVehicleMod(vehicle, 36, props.modSpeakers, false)
    end
    
    if props.modTrunk then
        SetVehicleMod(vehicle, 37, props.modTrunk, false)
    end
    
    if props.modHydrolic then
        SetVehicleMod(vehicle, 38, props.modHydrolic, false)
    end
    
    if props.modEngineBlock then
        SetVehicleMod(vehicle, 39, props.modEngineBlock, false)
    end
    
    if props.modAirFilter then
        SetVehicleMod(vehicle, 40, props.modAirFilter, false)
    end
    
    if props.modStruts then
        SetVehicleMod(vehicle, 41, props.modStruts, false)
    end
    
    if props.modArchCover then
        SetVehicleMod(vehicle, 42, props.modArchCover, false)
    end
    
    if props.modAerials then
        SetVehicleMod(vehicle, 43, props.modAerials, false)
    end
    
    if props.modTrimB then
        SetVehicleMod(vehicle, 44, props.modTrimB, false)
    end
    
    if props.modTank then
        SetVehicleMod(vehicle, 45, props.modTank, false)
    end
    
    if props.modWindows then
        SetVehicleMod(vehicle, 46, props.modWindows, false)
    end
    
    if props.modLivery then
        SetVehicleMod(vehicle, 48, props.modLivery, false)
        SetVehicleLivery(vehicle, props.modLivery)
    end
end

-- Donner les clés d'un véhicule
function Framework.Vehicles:GiveKeys(source, plate)
    if not self.keys[plate] then
        self.keys[plate] = {}
    end
    
    if not Framework.Utils:TableContains(self.keys[plate], source) then
        table.insert(self.keys[plate], source)
    end
    
    Framework.Events:TriggerClient(source, 'framework:vehicles:keysReceived', plate)
end

-- Retirer les clés d'un véhicule
function Framework.Vehicles:RemoveKeys(source, plate)
    if not self.keys[plate] then return end
    
    for i, playerId in pairs(self.keys[plate]) do
        if playerId == source then
            table.remove(self.keys[plate], i)
            break
        end
    end
    
    Framework.Events:TriggerClient(source, 'framework:vehicles:keysRemoved', plate)
end

-- Vérifier si un joueur a les clés
function Framework.Vehicles:HasKeys(source, plate)
    if not self.keys[plate] then return false end
    
    return Framework.Utils:TableContains(self.keys[plate], source)
end

-- Générer une plaque
function Framework.Vehicles:GeneratePlate()
    local plate = ''
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    
    for i = 1, 8 do
        local randomIndex = math.random(1, #chars)
        plate = plate .. chars:sub(randomIndex, randomIndex)
    end
    
    -- Vérifier si la plaque existe déjà
    if self.owned[plate] then
        return self:GeneratePlate()
    end
    
    return plate
end

-- Système de carburant
function Framework.Vehicles:StartFuelSystem()
    CreateThread(function()
        while true do
            Wait(60000) -- 1 minute
            
            for vehicle, data in pairs(self.spawned) do
                if DoesEntityExist(vehicle) then
                    local fuel = GetVehicleFuelLevel(vehicle)
                    local engine = GetIsVehicleEngineRunning(vehicle)
                    
                    if engine and fuel > 0 then
                                                local newFuel = math.max(0, fuel - self.fuelDecayRate)
                        SetVehicleFuelLevel(vehicle, newFuel)
                        
                        -- Arrêter le moteur si plus de carburant
                        if newFuel <= 0 then
                            SetVehicleEngineOn(vehicle, false, false, true)
                        end
                    end
                end
            end
        end
    end)
end

-- Sauvegarder un véhicule
function Framework.Vehicles:SaveVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local vehicleData = self.owned[plate]
    
    if not vehicleData then return false end
    
    local props = self:GetVehicleProperties(vehicle)
    local coords = GetEntityCoords(vehicle)
    
    -- Mettre à jour les données
    vehicleData.props = props
    vehicleData.fuel = GetVehicleFuelLevel(vehicle)
    vehicleData.engine = GetVehicleEngineHealth(vehicle)
    vehicleData.body = GetVehicleBodyHealth(vehicle)
    vehicleData.lastUsed = os.time()
    
    -- Sauvegarder en base
    Framework.Database:Execute('UPDATE vehicles SET props = ?, fuel = ?, engine = ?, body = ?, lastUsed = ? WHERE plate = ?', {
        json.encode(props),
        vehicleData.fuel,
        vehicleData.engine,
        vehicleData.body,
        vehicleData.lastUsed,
        plate
    })
    
    return true
end

-- Ranger un véhicule au garage
function Framework.Vehicles:StoreVehicle(source, vehicle, garage)
    if not DoesEntityExist(vehicle) then return false end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local vehicleData = self.owned[plate]
    
    if not vehicleData then
        Framework.Events:TriggerClient(source, 'framework:vehicles:notify', 
            'Ce véhicule ne vous appartient pas', 'error')
        return false
    end
    
    local player = Framework.Players:GetPlayer(source)
    if vehicleData.owner ~= player.identifier then
        Framework.Events:TriggerClient(source, 'framework:vehicles:notify', 
            'Ce véhicule ne vous appartient pas', 'error')
        return false
    end
    
    -- Sauvegarder le véhicule
    self:SaveVehicle(vehicle)
    
    -- Mettre à jour le garage
    vehicleData.garage = garage
    vehicleData.impound = false
    
    Framework.Database:Execute('UPDATE vehicles SET garage = ?, impound = 0 WHERE plate = ?', {
        garage, plate
    })
    
    -- Supprimer le véhicule du monde
    self:DeleteVehicle(vehicle)
    
    Framework.Events:TriggerClient(source, 'framework:vehicles:notify', 
        'Véhicule rangé au garage', 'success')
    
    return true
end

-- Sortir un véhicule du garage
function Framework.Vehicles:RetrieveVehicle(source, plate, spawnCoords, heading)
    local vehicleData = self.owned[plate]
    
    if not vehicleData then
        Framework.Events:TriggerClient(source, 'framework:vehicles:notify', 
            'Véhicule introuvable', 'error')
        return false
    end
    
    local player = Framework.Players:GetPlayer(source)
    if vehicleData.owner ~= player.identifier then
        Framework.Events:TriggerClient(source, 'framework:vehicles:notify', 
            'Ce véhicule ne vous appartient pas', 'error')
        return false
    end
    
    if vehicleData.impound then
        Framework.Events:TriggerClient(source, 'framework:vehicles:notify', 
            'Ce véhicule est en fourrière', 'error')
        return false
    end
    
    -- Vérifier si le véhicule est déjà sorti
    for entity, data in pairs(self.spawned) do
        if data.plate == plate then
            Framework.Events:TriggerClient(source, 'framework:vehicles:notify', 
                'Ce véhicule est déjà sorti', 'error')
            return false
        end
    end
    
    -- Faire apparaître le véhicule
    local vehicle = self:SpawnVehicle(source, vehicleData.model, spawnCoords, heading, plate, vehicleData.props)
    
    if vehicle then
        -- Appliquer les dégâts
        SetVehicleEngineHealth(vehicle, vehicleData.engine)
        SetVehicleBodyHealth(vehicle, vehicleData.body)
        SetVehicleFuelLevel(vehicle, vehicleData.fuel)
        
        Framework.Events:TriggerClient(source, 'framework:vehicles:notify', 
            'Véhicule sorti du garage', 'success')
        
        return true
    end
    
    return false
end

-- Mettre un véhicule en fourrière
function Framework.Vehicles:ImpoundVehicle(plate, reason, cost)
    local vehicleData = self.owned[plate]
    
    if not vehicleData then return false end
    
    -- Mettre à jour les données
    vehicleData.impound = true
    vehicleData.impoundReason = reason or 'Infraction au code de la route'
    vehicleData.impoundCost = cost or 500
    
    Framework.Database:Execute('UPDATE vehicles SET impound = 1, impoundReason = ?, impoundCost = ? WHERE plate = ?', {
        vehicleData.impoundReason,
        vehicleData.impoundCost,
        plate
    })
    
    -- Supprimer le véhicule du monde s'il existe
    for entity, data in pairs(self.spawned) do
        if data.plate == plate then
            self:DeleteVehicle(entity)
            break
        end
    end
    
    return true
end

-- Sortir un véhicule de la fourrière
function Framework.Vehicles:ReleaseVehicle(source, plate)
    local vehicleData = self.owned[plate]
    
    if not vehicleData then return false end
    
    if not vehicleData.impound then
        Framework.Events:TriggerClient(source, 'framework:vehicles:notify', 
            'Ce véhicule n\'est pas en fourrière', 'error')
        return false
    end
    
    local player = Framework.Players:GetPlayer(source)
    if vehicleData.owner ~= player.identifier then
        Framework.Events:TriggerClient(source, 'framework:vehicles:notify', 
            'Ce véhicule ne vous appartient pas', 'error')
        return false
    end
    
    -- Vérifier si le joueur peut payer
    if not player:CanAfford(vehicleData.impoundCost) then
        Framework.Events:TriggerClient(source, 'framework:vehicles:notify', 
            ('Vous n\'avez pas assez d\'argent (%s$)'):format(vehicleData.impoundCost), 'error')
        return false
    end
    
    -- Prendre l'argent et libérer le véhicule
    player:RemoveMoney('cash', vehicleData.impoundCost)
    
    vehicleData.impound = false
    vehicleData.impoundReason = nil
    vehicleData.impoundCost = nil
    vehicleData.garage = 'impound'
    
    Framework.Database:Execute('UPDATE vehicles SET impound = 0, impoundReason = NULL, impoundCost = NULL, garage = ? WHERE plate = ?', {
        'impound', plate
    })
    
    Framework.Events:TriggerClient(source, 'framework:vehicles:notify', 
        'Véhicule libéré de la fourrière', 'success')
    
    return true
end

-- Obtenir les véhicules d'un joueur
function Framework.Vehicles:GetPlayerVehicles(identifier)
    local vehicles = {}
    
    for plate, vehicleData in pairs(self.owned) do
        if vehicleData.owner == identifier then
            table.insert(vehicles, vehicleData)
        end
    end
    
    return vehicles
end

-- Obtenir les statistiques du système
function Framework.Vehicles:GetStats()
    return {
        ownedVehicles = Framework.Utils:TableSize(self.owned),
        spawnedVehicles = Framework.Utils:TableSize(self.spawned),
        totalKeys = Framework.Utils:TableSize(self.keys),
        garages = Framework.Utils:TableSize(self.garages),
        shops = Framework.Utils:TableSize(self.shops),
        fuelDecayRate = self.fuelDecayRate
    }
end

-- Événements
Framework.Events:Register('framework:vehicles:spawnVehicle', function(source, model, coords, heading)
    Framework.Vehicles:SpawnVehicle(source, model, coords, heading)
end)

Framework.Events:Register('framework:vehicles:deleteVehicle', function(source, vehicle)
    Framework.Vehicles:DeleteVehicle(vehicle)
end)

Framework.Events:Register('framework:vehicles:giveKeys', function(source, target, plate)
    Framework.Vehicles:GiveKeys(target, plate)
end)

Framework.Events:Register('framework:vehicles:storeVehicle', function(source, vehicle, garage)
    Framework.Vehicles:StoreVehicle(source, vehicle, garage)
end)

Framework.Events:Register('framework:vehicles:retrieveVehicle', function(source, plate, coords, heading)
    Framework.Vehicles:RetrieveVehicle(source, plate, coords, heading)
end)

print('^2[Rowden Framework]^0 Vehicles system loaded')

