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
    local char = player.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            if not espFolder:FindFirstChild(player.Name .. "_ESP") then
                local highlight = Instance.new("Highlight")
                highlight.Name = player.Name .. "_ESP"
                highlight.FillColor = Color3.new(1, 0, 0)
                highlight.FillTransparency = 0.5
                highlight.OutlineColor = Color3.new(1, 1, 1)
                highlight.OutlineTransparency = 0
                highlight.Adornee = char
                highlight.Parent = espFolder
            end
        end
    end
end

local function removeESP(player)
    local highlight = espFolder:FindFirstChild(player.Name .. "_ESP")
    if highlight then
        highlight:Destroy()
    end
end

local function updateESP()
    if not ESP_ENABLED then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local humanoid = p.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                createESP(p)
            else
                removeESP(p)
            end
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
    -- При появлении персонажа создаём ESP (если включено)
    if ESP_ENABLED then
        createESP(player)
    end
end

-- Подключаем обработчики для существующих игроков
for _, player in pairs(Players:GetPlayers()) do
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

-- Подключаем к новым игрокам
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(onCharacterAdded)
end)

-- Кнопка переключения ESP в UI
MainSection:NewToggle("ESP", "Подсвечивает игроков", function(state)
    ESP_ENABLED = state
    if not ESP_ENABLED then
        clearESP()
    else
        updateESP()
    end
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
