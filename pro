local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()

local Window = Library.CreateLib("Xeno Menu", "RJTheme3")

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local char = lp.Character or lp.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

-- Главная вкладка
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
    if noclip and lp.Character then
        for _, part in pairs(lp.Character:GetDescendants()) do
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

-- Телепорт вкладка
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
        selectedPlayer = nil
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

-- ESP вкладка
local ESPTab = Window:NewTab("ESP")
local ESPSection = ESPTab:NewSection("Подсветка игроков")

local ESP_ENABLED = false
local ESP_ShowBoxes = false
local ESP_ShowNames = false
local ESP_ShowTracers = false
local ESP_ShowChams = false
local ESP_Distance = 1000

local ESP_Color = Color3.fromRGB(255, 0, 0) -- Цвет по умолчанию (красный)

local boxes = {}
local names = {}
local tracers = {}
local chams = {}

-- Функция создания чамса (прозрачного цвета на теле)
local function createCham(player)
    if chams[player.Name] then return end
    local chamParts = {}

    local function applyCham(part)
        if part:IsA("BasePart") then
            local cham = Instance.new("BoxHandleAdornment")
            cham.Adornee = part
            cham.AlwaysOnTop = true
            cham.ZIndex = 10
            cham.Size = part.Size
            cham.Transparency = 0.5
            cham.Color3 = ESP_Color
            cham.Parent = part
            table.insert(chamParts, cham)
        end
    end

    local char = player.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            applyCham(part)
        end
    end

    chams[player.Name] = chamParts
end

local function removeCham(player)
    if chams[player.Name] then
        for _, cham in pairs(chams[player.Name]) do
            if cham and cham.Parent then
                cham:Destroy()
            end
        end
        chams[player.Name] = nil
    end
end

local function createBox(player)
    if boxes[player.Name] then return end
    local box = Drawing.new("Square")
    box.Color = ESP_Color
    box.Thickness = 2
    box.Filled = false
    box.Visible = true
    boxes[player.Name] = box
end

local function createNameTag(player)
    if names[player.Name] then return end
    local bill = Instance.new("BillboardGui")
    bill.Name = player.Name .. "_ESP_Name"
    bill.Adornee = player.Character and player.Character:FindFirstChild("HumanoidRootPart") or nil
    bill.Size = UDim2.new(0, 100, 0, 50)
    bill.AlwaysOnTop = true
    bill.Parent = lp:WaitForChild("PlayerGui")

    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = ESP_Color
    textLabel.TextStrokeTransparency = 0
    textLabel.Text = player.Name
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextScaled = true
    textLabel.Parent = bill

    names[player.Name] = bill
end

local function createTracer(player)
    if tracers[player.Name] then return end
    local line = Drawing.new("Line")
    line.Color = ESP_Color
    line.Thickness = 1.5
    line.Transparency = 1
    line.Visible = true
    tracers[player.Name] = line
end

local function removeESP(player)
    if boxes[player.Name] then
        boxes[player.Name]:Remove()
        boxes[player.Name] = nil
    end
    if names[player.Name] then
        names[player.Name]:Destroy()
        names[player.Name] = nil
    end
    if tracers[player.Name] then
        tracers[player.Name]:Remove()
        tracers[player.Name] = nil
    end
    removeCham(player)
end

local function updateESPColor(newColor)
    ESP_Color = newColor
    -- Обновляем цвета уже существующих элементов
    for _, box in pairs(boxes) do
        box.Color = ESP_Color
    end
    for _, bill in pairs(names) do
        bill.TextLabel.TextColor3 = ESP_Color
    end
    for _, line in pairs(tracers) do
        line.Color = ESP_Color
    end
    -- Обновляем чамсы
    for playerName, adornments in pairs(chams) do
        for _, adorn in pairs(adornments) do
            adorn.Color3 = ESP_Color
        end
    end
end

ESPSection:NewToggle("Включить ESP", "", function(state)
    ESP_ENABLED = state
    if not state then
        for _, player in pairs(Players:GetPlayers()) do
            removeESP(player)
        end
    end
end)

ESPSection:NewToggle("Показывать боксы", "", function(state)
    ESP_ShowBoxes = state
end)

ESPSection:NewToggle("Показывать имена", "", function(state)
    ESP_ShowNames = state
end)

ESPSection:NewToggle("Показывать линии", "", function(state)
    ESP_ShowTracers = state
end)

ESPSection:NewToggle("Показывать чамсы", "", function(state)
    ESP_ShowChams = state
end)

ESPSection:NewColorPicker("Цвет ESP", "Выбрать цвет для ESP и Чамса", function(color)
    updateESPColor(color)
end)

RunService.RenderStepped:Connect(function()
    if not ESP_ENABLED then return end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            if dist <= ESP_Distance then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    -- Чамсы
                    if ESP_ShowChams then
                        createCham(player)
                        -- Обновляем цвет на всякий случай
                        for _, adorn in pairs(chams[player.Name]) do
                            adorn.Color3 = ESP_Color
                        end
                    else
                        removeCham(player)
                    end

                    -- Боксы
                    if ESP_ShowBoxes then
                        createBox(player)
                        local size = 50 * (100 / dist)
                        boxes[player.Name].Position = Vector2.new(pos.X - size / 2, pos.Y - size / 2)
                        boxes[player.Name].Size = Vector2.new(size, size)
                        boxes[player.Name].Visible = true
                        boxes[player.Name].Color = ESP_Color
                    else
                        if boxes[player.Name] then
                            boxes[player.Name].Visible = false
                        end
                    end

                    -- Имена
                    if ESP_ShowNames then
                        createNameTag(player)
                        local bill = names[player.Name]
                        if bill then
                            bill.Adornee = hrp
                            bill.TextLabel.TextColor3 = ESP_Color
                        end
                    else
                        if names[player.Name] then
                            names[player.Name]:Destroy()
                            names[player.Name] = nil
                        end
                    end

                    -- Линии
                    if ESP_ShowTracers then
                        createTracer(player)
                        local line = tracers[player.Name]
                        if line then
                            line.From = center
                            line.To = Vector2.new(pos.X, pos.Y)
                            line.Color = ESP_Color
                            line.Visible = true
                        end
                    else
                        if tracers[player.Name] then
                            tracers[player.Name].Visible = false
                        end
                    end

                else
                    -- Игрок вне экрана — скрываем все
                    if boxes[player.Name] then boxes[player.Name].Visible = false end
                    if tracers[player.Name] then tracers[player.Name].Visible = false end
                    if names[player.Name] then
                        names[player.Name]:Destroy()
                        names[player.Name] = nil
                    end
                    removeCham(player)
                end
            else
                -- Игрок слишком далеко — скрываем все
                if boxes[player.Name] then boxes[player.Name].Visible = false end
                if tracers[player.Name] then tracers[player.Name].Visible = false end
                if names[player.Name] then
                    names[player.Name]:Destroy()
                    names[player.Name] = nil
                end
                removeCham(player)
            end
        else
            -- Нет персонажа — убираем ESP
            removeESP(player)
        end
    end
end)

-- Очистка ESP при выходе игрока
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)
