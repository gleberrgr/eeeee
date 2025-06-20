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
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "XenoESP"

local function clearESP()
    for _, v in pairs(espFolder:GetChildren()) do
        v:Destroy()
    end
end

local function removeESP(player)
    local highlight = espFolder:FindFirstChild(player.Name .. "_ESP")
    if highlight then
        highlight:Destroy()
    end
end

local function createESP(player)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
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

            -- Подключаем удаление ESP при смерти, если ещё не подключено
            if not humanoid:FindFirstChild("ESPDeathConn") then
                local connMarker = Instance.new("BoolValue")
                connMarker.Name = "ESPDeathConn"
                connMarker.Parent = humanoid

                humanoid.Died:Connect(function()
                    removeESP(player)
                end)
            end
        end
    end
end

local function updateESP()
    if not ESP_ENABLED then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp then
            createESP(p)
        end
    end
end

local function onCharacterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    local humanoid = character:WaitForChild("Humanoid")

    humanoid.Died:Connect(function()
        removeESP(player)
    end)

    if ESP_ENABLED then
        createESP(player)
    end
end

for _, player in pairs(Players:GetPlayers()) do
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(onCharacterAdded)
end)

ESPSection:NewToggle("Включить ESP", "Подсвечивает игроков", function(state)
    ESP_ENABLED = state
    if not ESP_ENABLED then
        clearESP()
    else
        updateESP()
    end
end)

-- === ВКЛАДКА АИМБОТА ===
local AimTab = Window:NewTab("Аимбот")
local AimSection = AimTab:NewSection("Настройки аимбота")

local aimbotEnabled = false
local aimRadius = 60
local aimKey = Enum.KeyCode.E -- клавиша для аимбота

AimSection:NewToggle("Включить аимбот", "Автоматический прицел на игроков", function(state)
    aimbotEnabled = state
end)

AimSection:NewSlider("Радиус прицела", "Угол вокруг курсора для прицела", 100, 10, function(value)
    aimRadius = value
end)

AimSection:NewKeybind("Клавиша аимбота", "Удерживайте, чтобы аимбот работал", aimKey, function()
    -- В этом UI кейбинд – по нажатию/отпусканию не всегда можно, но имитируем с toggling
end)

local isAimKeyDown = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == aimKey then
        isAimKeyDown = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == aimKey then
        isAimKeyDown = false
    end
end)

local function getNearestTarget()
    local nearestPlayer = nil
    local nearestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid.Health > 0 then
                local pos = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                local onScreen = pos.Z > 0
                if onScreen then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (screenPos - mousePos).Magnitude
                    if distance < aimRadius and distance < nearestDistance then
                        nearestDistance = distance
                        nearestPlayer = player
                    end
                end
            end
        end
    end

    return nearestPlayer
end

RunService.RenderStepped:Connect(function()
    if aimbotEnabled and isAimKeyDown and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local target = getNearestTarget()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = target.Character.HumanoidRootPart.Position
            local camPos = Camera.CFrame.Position
            local direction = (targetPos - camPos).Unit

            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(camPos, camPos + direction)
            -- Плавное наведение
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, 0.3)
        end
    end
end)

-- === НАСТРОЙКИ ===
local SettingsTab = Window:NewTab("Настройки")
local SettingsSection = SettingsTab:NewSection("Интерфейс и горячие клавиши")

SettingsSection:NewDropdown("Сменить тему", "Выберите тему интерфейса", Themes, function(theme)
    currentTheme = theme
    -- Просто перезагружаем UI (нужно перезапустить скрипт для эффекта)
end)

local toggleKey = Enum.KeyCode.RightControl
SettingsSection:NewKeybind("Клавиша скрытия GUI", "Нажмите, чтобы скрыть/показать меню", toggleKey, function()
    for _, gui in ipairs(game.CoreGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name:find("RJ") then
            gui.Enabled = not gui.Enabled
        end
    end
end)

-- Обновляем ссылки при респавне
lp.CharacterAdded:Connect(function(newChar)
    char = newChar
    humanoid = newChar:WaitForChild("Humanoid")
end)
