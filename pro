local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()

local Themes = {
    "RJTheme1", "RJTheme2", "RJTheme3", "RJTheme4",
    "RJTheme5", "RJTheme6", "RJTheme7", "RJTheme8"
}

local currentTheme = "RJTheme3"
local Window = Library.CreateLib("Xeno Menu", currentTheme)

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local char = lp.Character or lp.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

-- === ГЛАВНАЯ ВКЛАДКА ===
local MainTab = Window:NewTab("Главное")
local MainSection = MainTab:NewSection("Основные функции")

local infiniteJump = false
MainSection:NewToggle("Бесконечный прыжок", "Позволяет прыгать бесконечно", function(state)
    infiniteJump = state
end)

UserInputService.JumpRequest:Connect(function()
    if infiniteJump and lp.Character then
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState("Jumping")
        end
    end
end)

local noclip = false
MainSection:NewToggle("Ноуклип", "Проходить сквозь стены", function(state)
    noclip = state
end)

RunService.Stepped:Connect(function()
    if lp.Character and noclip then
        for _, part in ipairs(lp.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

MainSection:NewSlider("Скорость", "Изменяет скорость персонажа", 100, 16, function(value)
    if humanoid then
        humanoid.WalkSpeed = value
    end
end)

-- === ВКЛАДКА ТЕЛЕПОРТА ===
local TeleportTab = Window:NewTab("Телепорт")
local TeleportSection = TeleportTab:NewSection("Телепорт к игроку")

local dropdownNames = {}
local dropdownObject
local selectedPlayer

local function updateDropdown()
    table.clear(dropdownNames)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            table.insert(dropdownNames, p.Name)
        end
    end

    if dropdownObject then
        dropdownObject:Refresh(dropdownNames, true)
    else
        dropdownObject = TeleportSection:NewDropdown("Игроки", "Выберите игрока", dropdownNames, function(option)
            selectedPlayer = option
        end)
    end
end

updateDropdown()

TeleportSection:NewButton("Обновить список", "Обновляет список игроков", function()
    updateDropdown()
end)

TeleportSection:NewButton("Телепортироваться", "Телепорт к выбранному игроку", function()
    if selectedPlayer and Players:FindFirstChild(selectedPlayer) then
        local targetChar = Players[selectedPlayer].Character
        local myChar = lp.Character
        if targetChar and myChar then
            local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
            local myHRP = myChar:FindFirstChild("HumanoidRootPart")
            if targetHRP and myHRP then
                myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
end)

Players.PlayerAdded:Connect(updateDropdown)
Players.PlayerRemoving:Connect(updateDropdown)

-- === ВКЛАДКА ESP ===
local ESPTab = Window:NewTab("ESP")
local ESPSection = ESPTab:NewSection("Подсветка игроков")

local ESP_ENABLED = false
local ESP_ShowBoxes = true
local ESP_ShowNames = true
local ESP_ShowTracers = true
local ESP_Distance = 1000 -- дистанция отрисовки ESP

local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "XenoESP"

local tracers = {}

local function clearESP()
    for _, v in pairs(espFolder:GetChildren()) do
        v:Destroy()
    end
    tracers = {}
end

local function removeESP(player)
    local highlight = espFolder:FindFirstChild(player.Name .. "_ESP")
    if highlight then
        highlight:Destroy()
    end
    -- Удаляем линии-трейсеры
    if tracers[player.Name] then
        tracers[player.Name]:Destroy()
        tracers[player.Name] = nil
    end
end

local function createESP(player)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        local distance = (Camera.CFrame.Position - character.HumanoidRootPart.Position).Magnitude
        if distance > ESP_Distance then
            removeESP(player)
            return
        end

        local espName = player.Name .. "_ESP"
        if not espFolder:FindFirstChild(espName) then
            local highlight = Instance.new("Highlight")
            highlight.Name = espName
            highlight.FillColor = Color3.new(1, 0, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.OutlineTransparency = 0
            highlight.Adornee = character
            highlight.Parent = espFolder
        end

        -- Создаем/обновляем линии-трейсеры
        if ESP_ShowTracers then
            if not tracers[player.Name] then
                local tracer = Drawing.new("Line")
                tracer.Color = Color3.new(1, 0, 0)
                tracer.Thickness = 1.5
                tracer.Transparency = 1
                tracer.Visible = true
                tracers[player.Name] = tracer
            end
        else
            if tracers[player.Name] then
                tracers[player.Name]:Remove()
                tracers[player.Name] = nil
            end
        end
    else
        removeESP(player)
    end
end

local function updateESP()
    if not ESP_ENABLED then
        clearESP()
        return
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp then
            createESP(p)
        end
    end
end

local function updateTracers()
    if not ESP_ENABLED or not ESP_ShowTracers then
        for _, tracer in pairs(tracers) do
            tracer.Visible = false
        end
        return
    end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

    for playerName, tracer in pairs(tracers) do
        local player = Players:FindFirstChild(playerName)
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
            if distance <= ESP_Distance then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    tracer.From = screenCenter
                    tracer.To = screenPos
                    tracer.Visible = true
                else
                    tracer.Visible = false
                end
            else
                tracer.Visible = false
            end
        else
            tracer.Visible = false
        end
    end
end

local boxes = {}

local function createBox(player)
    if boxes[player.Name] then return end

    local box = Drawing.new("Square")
    box.Color = Color3.new(1, 0, 0)
    box.Thickness = 2
    box.Transparency = 1
    box.Filled = false
    box.Visible = true
    boxes[player.Name] = box
end

local function removeBox(player)
    if boxes[player.Name] then
        boxes[player.Name]:Remove()
        boxes[player.Name] = nil
    end
end

local function updateBoxes()
    if not ESP_ENABLED or not ESP_ShowBoxes then
        for _, box in pairs(boxes) do
            box.Visible = false
        end
        return
    end

    for playerName, box in pairs(boxes) do
        local player = Players:FindFirstChild(playerName)
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
            if distance <= ESP_Distance then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local sizeFactor = 1000 / distance -- уменьшаем размер бокса с увеличением дистанции
                    local boxSize = Vector2.new(50, 100) * sizeFactor

                    box.Position = Vector2.new(pos.X - boxSize.X/2, pos.Y - boxSize.Y/2)
                    box.Size = boxSize
                    box.Visible = true
                else
                    box.Visible = false
                end
            else
                box.Visible = false
            end
        else
            box.Visible = false
        end
    end
end

local nameDrawings = {}

local function createName(player)
    if nameDrawings[player.Name] then return end

    local nameLabel = Drawing.new("Text")
    nameLabel.Color = Color3.new(1, 1, 1)
    nameLabel.Size = 16
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.Visible = true
    nameDrawings[player.Name] = nameLabel
end

local function removeName(player)
    if nameDrawings[player.Name] then
        nameDrawings[player.Name]:Remove()
        nameDrawings[player.Name] = nil
    end
end

local function updateNames()
    if not ESP_ENABLED or not ESP_ShowNames then
        for _, nameLabel in pairs(nameDrawings) do
            nameLabel.Visible = false
        end
        return
    end

    for playerName, nameLabel in pairs(nameDrawings) do
        local player = Players:FindFirstChild(playerName)
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
            if distance <= ESP_Distance then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                if onScreen then
                    nameLabel.Position = Vector2.new(pos.X, pos.Y)
                    nameLabel.Text = player.Name
                    nameLabel.Visible = true
                else
                    nameLabel.Visible = false
                end
            else
                nameLabel.Visible = false
            end
        else
            nameLabel.Visible = false
        end
    end
end

local function removeAllESP(player)
    removeESP(player)
    removeBox(player)
    removeName(player)
end

local function onCharacterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    local humanoid = character:WaitForChild("Humanoid")

    humanoid.Died:Connect(function()
        removeAllESP(player)
    end)

    if ESP_ENABLED then
        createESP(player)
        createBox(player)
        createName(player)
    end
end

for _, player in pairs(Players:GetPlayers()) do
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerRemoving:Connect(function(player)
    removeAllESP(player)
end)

-- ESP GUI элементы
ESPSection:NewToggle("Включить ESP", "Включает/выключает ESP", function(state)
    ESP_ENABLED = state
    if not state then
        clearESP()
        for _, box in pairs(boxes) do
            box.Visible = false
        end
        for _, nameLabel in pairs(nameDrawings) do
            nameLabel.Visible = false
        end
        for _, tracer in pairs(tracers) do
            tracer.Visible = false
        end
    else
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= lp and player.Character then
                createESP(player)
                createBox(player)
                createName(player)
            end
        end
    end
end)

ESPSection:NewToggle("Показывать боксы", "Показывать боксы вокруг игроков", function(state)
    ESP_ShowBoxes = state
    if not state then
        for _, box in pairs(boxes) do
            box.Visible = false
        end
    end
end)

ESPSection:NewToggle("Показывать имена", "Показывать имена игроков", function(state)
    ESP_ShowNames = state
    if not state then
        for _, nameLabel in pairs(nameDrawings) do
            nameLabel.Visible = false
        end
    end
end)

ESPSection:NewToggle("Показывать линии (tracers)", "Рисовать линии от центра экрана до игроков", function(state)
    ESP_ShowTracers = state
    if not state then
        for _, tracer in pairs(tracers) do
            tracer.Visible = false
        end
    end
end)

ESPSection:NewSlider("Макс. дистанция ESP", "Максимальная дистанция отрисовки ESP", 2000, 1000, function(value)
    ESP_Distance = value
end)

-- Главный цикл обновления ESP и трейсеров
RunService.RenderStepped:Connect(function()
    updateESP()
    updateBoxes()
    updateNames()
    updateTracers()
end)
