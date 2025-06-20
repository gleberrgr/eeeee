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
local ESP_ShowBoxes = true
local ESP_ShowNames = true
local ESP_ShowTracers = true
local ESP_Distance = 1000

local boxes = {}
local names = {}
local tracers = {}

ESPSection:NewToggle("Включить ESP", "", function(state)
    ESP_ENABLED = state
    if not state then
        -- Очищаем все
        for _, box in pairs(boxes) do box:Remove() end
        for _, nameTag in pairs(names) do nameTag:Destroy() end
        for _, tracer in pairs(tracers) do tracer:Remove() end
        boxes = {}
        names = {}
        tracers = {}
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

local function createBox(player)
    if boxes[player.Name] then return end
    local box = Drawing.new("Square")
    box.Color = Color3.fromRGB(255, 0, 0)
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
    bill.Parent = game.CoreGui

    local textLabel = Instance.new("TextLabel", bill)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 0, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.Text = player.Name
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextScaled = true

    names[player.Name] = bill
end

local function createTracer(player)
    if tracers[player.Name] then return end
    local line = Drawing.new("Line")
    line.Color = Color3.fromRGB(255, 0, 0)
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
end

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
                    -- Боксы
                    if ESP_ShowBoxes then
                        createBox(player)
                        local size = 50 * (100 / dist)
                        boxes[player.Name].Position = Vector2.new(pos.X - size / 2, pos.Y - size / 2)
                        boxes[player.Name].Size = Vector2.new(size, size)
                        boxes[player.Name].Visible = true
                    else
                        if boxes[player.Name] then
                            boxes[player.Name].Visible = false
                        end
                    end

                    -- Имена
                    if ESP_ShowNames then
                        createNameTag(player)
                        if names[player.Name].Adornee ~= hrp then
                            names[player.Name].Adornee = hrp
                        end
                        names[player.Name].Enabled = true
                    else
                        if names[player.Name] then
                            names[player.Name].Enabled = false
                        end
                    end

                    -- Линии
                    if ESP_ShowTracers then
                        createTracer(player)
                        tracers[player.Name].From = center
                        tracers[player.Name].To = Vector2.new(pos.X, pos.Y)
                        tracers[player.Name].Visible = true
                    else
                        if tracers[player.Name] then
                            tracers[player.Name].Visible = false
                        end
                    end
                else
                    removeESP(player)
                end
            else
                removeESP(player)
            end
        else
            removeESP(player)
        end
    end
end)
