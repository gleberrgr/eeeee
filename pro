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

local char = lp.Character or lp.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

-- === ГЛАВНОЕ ===
local MainTab = Window:NewTab("Главное")
local MainSection = MainTab:NewSection("Функции")

-- Бесконечный прыжок
local infiniteJump = false
MainSection:NewToggle("Бесконечный прыжок", "Позволяет прыгать бесконечно", function(state)
    infiniteJump = state
end)

UserInputService.JumpRequest:Connect(function()
    if infiniteJump and lp.Character then
        lp.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- Ноуклип
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

-- Изменение скорости
MainSection:NewSlider("Скорость", "Устанавливает скорость персонажа", 100, 16, function(s)
    if humanoid then
        humanoid.WalkSpeed = s
    end
end)

-- === ESP ===
local ESP_ENABLED = false
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "XenoESP"

local function clearESP()
    for _, v in pairs(espFolder:GetChildren()) do
        v:Destroy()
    end
end

local function createESP(player)
    if player.Character then
        local highlight = Instance.new("Highlight")
        highlight.Name = player.Name .. "_ESP"
        highlight.FillColor = Color3.new(1, 0, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.OutlineTransparency = 0
        highlight.Adornee = player.Character
        highlight.Parent = espFolder
    end
end

local function updateESP()
    clearESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            createESP(p)
        end
    end
end

MainSection:NewToggle("ESP", "Подсвечивает игроков", function(state)
    ESP_ENABLED = state
    if ESP_ENABLED then
        updateESP()
    else
        clearESP()
    end
end)

-- === AIMBOT ===
local AIMBOT_ENABLED = false
local aimRadius = 50 -- Радиус аима по умолчанию
local aimKeybind = Enum.KeyCode.X -- Горячая клавиша для аимбота

local function getClosestPlayerToCursor(radius)
    local mouse = lp:GetMouse()
    local closestPlayer = nil
    local shortestDistance = radius

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local hrp = player.Character.HumanoidRootPart
            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

RunService.RenderStepped:Connect(function()
    if AIMBOT_ENABLED then
        local target = getClosestPlayerToCursor(aimRadius)
        if target and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = target.Character.HumanoidRootPart
            local camera = workspace.CurrentCamera
            camera.CFrame = CFrame.new(camera.CFrame.Position, hrp.Position)
        end
    end
end)

MainSection:NewToggle("Aimbot", "Включить/выключить аимбот", function(state)
    AIMBOT_ENABLED = state
end)

MainSection:NewSlider("Радиус аима", "Радиус, в котором аимбот ищет цель", 300, 50, function(value)
    aimRadius = value
end)

MainSection:NewKeybind("Включить/выключить аимбот (Keybind)", "Горячая клавиша для аимбота", aimKeybind, function()
    AIMBOT_ENABLED = not AIMBOT_ENABLED
    print("Aimbot toggled:", AIMBOT_ENABLED)
end)

-- === ТЕЛЕПОРТ ===
local TeleportTab = Window:NewTab("Телепорт")
local TeleportSection = TeleportTab:NewSection("К игроку")

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
        dropdownObject = TeleportSection:NewDropdown("Игроки", "Выбери игрока", dropdownNames, function(option)
            selectedPlayer = option
        end)
    end
end

updateDropdown()

TeleportSection:NewButton("Обновить список", "Перезапускает дропдаун", function()
    updateDropdown()
end)

TeleportSection:NewButton("Телепортироваться", "Телепорт к выбранному игроку", function()
    if selectedPlayer and Players:FindFirstChild(selectedPlayer) then
        local targetChar = Players[selectedPlayer].Character
        if targetChar and lp.Character then
            local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
            local myHRP = lp.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP and myHRP then
                myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
end)

-- === НАСТРОЙКИ ===
local SettingsTab = Window:NewTab("Настройки")
local SettingsSection = SettingsTab:NewSection("Темы и UI")

SettingsSection:NewDropdown("Сменить тему", "Изменяет тему интерфейса", Themes, function(theme)
    currentTheme = theme
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()
    Window = Library.CreateLib("Xeno Menu", currentTheme)
end)

local toggleKey = Enum.KeyCode.RightControl
SettingsSection:NewKeybind("Скрыть/Показать GUI", "Изменить клавишу скрытия", toggleKey, function()
    for _, gui in ipairs(game.CoreGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name:find("RJ") then
            gui.Enabled = not gui.Enabled
        end
    end
end)

-- === СМЕРТЬ И ПЕРЕЗАГРУЗКА ===
lp.CharacterAdded:Connect(function(newChar)
    char = newChar
    humanoid = newChar:WaitForChild("Humanoid")
end)
