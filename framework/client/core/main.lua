Framework.Client = {
    ready = false,
    playerLoaded = false,
    playerData = {},
    ui = {
        isOpen = false,
        focusedElement = nil,
        nuiFocus = false
    },
    camera = {
        active = false,
        coords = nil,
        rotation = nil
    },
    controls = {
        disabled = {}
    }
}

-- Init
function Framework.Client:Init()
    self:RegisterEvents()
    self:RegisterKeybinds()
    self:StartThreads()

    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end

    self.ready = true
    Framework.Debug:Success('Client ready')

    Framework.Events.TriggerServer('framework:client:ready')
end

-- Events
function Framework.Client:RegisterEvents()
    Framework.Events:Register('framework:player:loaded', function(playerData)
        self.playerLoaded = true
        self.playerData = playerData

        Framework.Debug:Success('Player data loaded')
        Framework.Events:Trigger('framework:client:playerLoaded', playerData)
    end)

    Framework.Events:Register('framework:player:moneyChange', function(account, newAmount, change, reason)
        self.playerData[account] = newAmount

        self:UpdateUI('money', {
            account = account,
            amount = newAmount,
            change = change,
            reason = reason
        })
    end)

    Framework.Events:Register('framework:player:jobChange', function(job, grade, oldJob, oldGrade)
        self.playerData.job = job
        self.playerData.job_grade = grade

        self:UpdateUI('job', {
            job = job,
            grade = grade,
            oldJob = oldJob,
            oldGrade = oldGrade
        })

        Framework.Debug:Info(('Job changed to %s (Grade: %s)'):format(job, grade))
    end)

    Framework.Events:Register('framework:player:notify', function(component, data)
        self:UpdateUI(component, data)
    end)

    Framework.Events:Register('framework:player:updateUI', function(account, newAmount, change, reason)
        self.playerData[account] = newAmount

        self:UpdateUI('money', {
            account = account,
            amount = newAmount,
            change = change,
            reason = reason
        })
    end)
end

-- Raccourcis clavier
function Framework.Client:RegisterKeybinds()
    -- Menu Principal (F1)
    RegisterCommand('framework:mainmenu', function()
        if not self.playerLoaded then return end
        self:ToggleMainMenu()
    end, false)

    RegisterKeyMapping('framework:mainmenu', 'Ouvrir le menu principal', 'keyboard', 'F1')

    -- Inventaire (F2)
    RegisterCommand('framework:inventory', function()
        if not self.playerLoaded then return end
        self:OpenInventory()
    end, false)

    RegisterKeyMapping('framework:inventory', "Ouvrir l'inventaire", 'keyboard', 'F2')

    -- Téléphone (F3)
    RegisterCommand('framework:phone', function()
        if not self.playerLoaded then return end
        self:OpenPhone()
    end, false)

    RegisterKeyMapping('framework:phone', "Ouvrir le téléphone", 'keyboard', 'F3')

    -- Menu véhicule (F4)
    RegisterCommand('framework:vehiclemenu', function()
        if not self.playerLoaded then return end
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            self:OpenVehicleMenu()
        end
    end, false)

    RegisterKeyMapping('framework:vehiclemenu', "Ouvrir le menu véhicule", 'keyboard', 'F4')
end

-- Threads
function Framework.Client:StartThreads()
    -- Thread principal
    CreateThread(function()
        while true do
            local sleep = 1000

            if self.playerLoaded then
                -- Sauvegarde la position du joueur
                local player = PlayerPedId()
                local coords = GetEntityCoords(player)
                local heading = GetEntityHeading(player)

                self.playerData.position = {
                    x = coords.x,
                    y = coords.y, 
                    z = coords.z,
                    heading = heading
                }

                Framework.Events:TriggerServer('framework:player:updatePosition', self.plateData.position)
            end

            Wait(5000)
        end
    end)

    -- Thread des contrôle
    CreateThread(function()
        while true do
            local sleep = 5
            if self.playerLoaded then
                for control, disabled in pairs(self.controls.disabled) do
                    if disabled then
                        DisableControlAction(0, control, true)
                    end
                end

                self:CheckInteractions()
            else
                sleep = 1000
            end

            Wait(sleep)
        end
    end)

    -- Thread de l'ui
    CreateThread(function()
        while true do
            local sleep = 100

            if self.playerLoaded then
                self:UpdateHUD()

                if self.ui.nuiFocus then
                    SetNuiFocus(true, true)
                    self:DisableControls()
                else
                    SetNuiFocus(false, false)
                    self:EnableControls()
                end
            else
                sleep = 1000
            end

            Wait(sleep)
        end
    end)
end

function Framework.Client:CheckInteractions()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)

    -- ! EXEMPLE
    local closestNPC = GetClosestPed(coords.x, coords.y, coords.z, 3.0, true, false, 0, false, true)
    if closestNPC ~= 0 then
        self:ShowInteraction('Parler', 'E')

        if IsControlJustPressed(0, 38) then -- E
            Framework.Client:ShowNotification('Vous avez intéragi avec un pnj')
        end
    end
end

-- Affiche une interaction
function Framework.Client:ShowInteraction(text, key)
    SendNuiMessage({
        type = 'interaction',
        text = text,
        key = key
    })
end

-- Cache une interaction
function Framework.Client:HideInteraction()
    SendNuiMessage({
        type = 'hideInteraction',
    })
end

-- Ouvre le menu principal
function Framework.Client:ToggleMainMenu()
    if self.ui.isOpen then
        self:CloseUI()
    else
        self:OpenMenuMenu()
    end
end

function Framework.Client:OpenMainMenu()
    self.ui.isOpen = true
    self.ui.nuiFocus = true

    SendNuiMessage({
        type = 'openMainMenu',
        playerData = self.playerData
    })
end

-- Ouvre l'inventaire
function Framework.Client:OpenInventory()
    self.ui.isOpen = true
    self.ui.nuiFocus = true

    SendNuiMessage({
        type = 'openInventory',
        playerData = self.playerData.inventory
    })
end

-- Ouvre le téléphone
function Framework.Client:OpenPhone()
    self.ui.isOpen = true
    self.ui.nuiFocus = true

    SendNuiMessage({
        type = 'openPhone',
        playerData = self.playerData
    })
end

-- Ouvre le menu véhicule
function Framework.Client:OpenVehicleMenu()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)

    if vehicle == 0 then return end

    self.ui.isOpen = true
    self.ui.nuiFocus = true

    SendNuiMessage({
        type = 'openVehicleMenu',
        vehicle = {
            model = GetDisplayNameFromVehicleModel(vehicle),
            plate = GetVehicleNumberPlateText(vehicle),
            fuel = GetVehicleFuelLevel(vehicle),
            engine = GetVehicleEngineHealth(vehicle),
            body = GetVehicleBodyHealth(vehicle)
        }
    })
end

-- Ferme l'interace
function Framework.Client:CloseUI()
    self.ui.isOpen = false
    self.ui.nuiFocus = false

    SendNuiMessage({
        type = 'closeUI'
    })
end

-- Met à jour l'interface
function Framework.Client:UpdateUI(component, data)
    SendNuiMessage({
        type = 'updateUI',
        component = component,
        data = data
    })
end

-- Met à jour l'HUD
function Framework.Client:UpdateHUD()
    SendNuiMessage({
        type = 'updateHUD',
        playerData = {
            money = self.playerData.money,
            bank = self.playerData.bank,
            job = self.playerData.job,
            job_grade = self.playerData.job_grade,
        }
    })
end

function Framework.Client:ShowNotification(message, type, duration)
    SendNuiMessage({
        type = 'showNotification',
        message = message,
        notificationType = type or 'info',
        duration = duration or 5000
    })
end

-- Désactive les controles
function Framework.Client:DisableControls()
    local controlsToDisable = {
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
        21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
        39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56,
        57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74,
        75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92,
        93, 94, 95, 96, 97, 98, 99, 100
    }
    
    for _, control in pairs(controlsToDisable) do
        self.controls.disabled[control] = true
    end
end

-- Active les controles
function Framework.Client:EnableControls()
    for control, _ in pairs(self.controls.disabled) do
        self.controls.disabled[control] = false
    end
end

-- Get les datas du joueur
function Framework.Client:GetPlayerData()
    return self.playerData
end

-- Met à jour les datas du joueur
function Framework.Client:UpdatePlayerData(key, value)
    self.playerData[key] = value
end

-- Vérifie si le joueur est bien laod
function Framework.Client:IsPlayerLoaded()
    return self.playerLoaded
end

-- Récupère les infos du joueur
function Framework.Client:GetStats()
    return {
        ready = self.ready,
        playerLoaded = self.playerLoaded,
        uiOpen = self.ui.isOpen,
        nuiFocus = self.ui.nuiFocus,
        disabledControls = Framework.Utils:TableSize(self.controls.disabled)
    }
end

print('^2[Rowden Framework]^0 Client core loaded')