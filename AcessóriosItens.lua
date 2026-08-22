-- =========================================================
-- MENU DE SELEÇÃO INICIAL
-- =========================================================
local selectedItems = {
    BloxyCola   = false,
    TzesPhone   = false,
    Lanterna    = false,
    TzeSprayCan = false
}

local menuConfirmed = false

do
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local Workspace = game:GetService("Workspace")

    if CoreGui:FindFirstChild("TzeSelectMenu") then
        CoreGui.TzeSelectMenu:Destroy()
    end

    local SelectGui = Instance.new("ScreenGui")
    SelectGui.Name = "TzeSelectMenu"
    SelectGui.ResetOnSpawn = false
    SelectGui.IgnoreGuiInset = true
    SelectGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SelectGui.Parent = CoreGui

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 210, 0, 155)
    Main.Position = UDim2.new(0.5, -105, 0.5, -78)
    Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    Main.BorderSizePixel = 0
    Main.Parent = SelectGui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

    -- Escala adaptativa para todos os dispositivos
    local selectUIScale = Instance.new("UIScale")
    selectUIScale.Parent = Main
    local function updateSelectScale()
        local cam = Workspace.CurrentCamera
        if cam then
            local size = cam.ViewportSize
            local scale = math.clamp(math.min(size.X / 420, size.Y / 320), 0.65, 1.4)
            selectUIScale.Scale = scale
        end
    end
    updateSelectScale()
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSelectScale)
    end

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 205, 50)
    stroke.Thickness = 2
    stroke.Parent = Main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 22)
    title.Position = UDim2.new(0, 0, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = "Escolha os itens"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.Parent = Main

    local items = {
        {Key = "BloxyCola",   Emoji = "🥤", Name = "Cola"},
        {Key = "TzesPhone",   Emoji = "📱", Name = "Phone"},
        {Key = "Lanterna",    Emoji = "🔦", Name = "Lanterna"},
        {Key = "TzeSprayCan", Emoji = "🎨", Name = "Spray"}
    }

    local toggleButtons = {}

    for i, data in ipairs(items) do
        local btn = Instance.new("TextButton")
        btn.Name = data.Key
        btn.Size = UDim2.new(0, 92, 0, 28)
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        btn.Position = UDim2.new(0, 10 + col * 98, 0, 32 + row * 34)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        btn.Text = data.Emoji .. " " .. data.Name
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.AutoButtonColor = false
        btn.Parent = Main
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(60, 60, 70)
        btnStroke.Thickness = 1.2
        btnStroke.Parent = btn

        toggleButtons[data.Key] = {button = btn, stroke = btnStroke, selected = false}

        btn.MouseButton1Click:Connect(function()
            local info = toggleButtons[data.Key]
            info.selected = not info.selected
            if info.selected then
                info.button.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
                info.button.TextColor3 = Color3.fromRGB(10, 10, 15)
                info.stroke.Color = Color3.fromRGB(40, 160, 40)
            else
                info.button.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
                info.button.TextColor3 = Color3.fromRGB(200, 200, 200)
                info.stroke.Color = Color3.fromRGB(60, 60, 70)
            end
        end)
    end

    local allBtn = Instance.new("TextButton")
    allBtn.Size = UDim2.new(0, 92, 0, 26)
    allBtn.Position = UDim2.new(0, 10, 0, 104)
    allBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    allBtn.Text = "✓ Todos"
    allBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    allBtn.Font = Enum.Font.GothamBold
    allBtn.TextSize = 11
    allBtn.AutoButtonColor = false
    allBtn.Parent = Main
    Instance.new("UICorner", allBtn).CornerRadius = UDim.new(0, 7)

    allBtn.MouseButton1Click:Connect(function()
        for key, info in pairs(toggleButtons) do
            info.selected = true
            info.button.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
            info.button.TextColor3 = Color3.fromRGB(10, 10, 15)
            info.stroke.Color = Color3.fromRGB(40, 160, 40)
        end
    end)

    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Size = UDim2.new(0, 92, 0, 26)
    confirmBtn.Position = UDim2.new(0, 108, 0, 104)
    confirmBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
    confirmBtn.Text = "Confirmar"
    confirmBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.TextSize = 12
    confirmBtn.AutoButtonColor = false
    confirmBtn.Parent = Main
    Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 7)

    confirmBtn.MouseButton1Click:Connect(function()
        for key, info in pairs(toggleButtons) do
            selectedItems[key] = info.selected
        end
        menuConfirmed = true
        SelectGui:Destroy()
    end)

    while not menuConfirmed do
        task.wait(0.1)
    end
end

-- =========================================================
-- CRIA PASTA ORGANIZADA: PHONE / Music + Photos
-- =========================================================
local function criarPastasPhone()
    pcall(function()
        if not isfolder("PHONE") then
            makefolder("PHONE")
        end
        if not isfolder("PHONE/Music") then
            makefolder("PHONE/Music")
        end
        if not isfolder("PHONE/Photos") then
            makefolder("PHONE/Photos")
        end
    end)
end

criarPastasPhone()

-- =========================================================
-- SCRIPT PRINCIPAL (só cria o que foi selecionado)
-- =========================================================
local SETTINGS = {
    JumpPower        = 50,
    Enabled          = true,
    DrinkDuration    = 3,
    BoostDuration    = 15,
    BoostSpeed       = 35,
    BoostJump        = 17,
    BoostFOV         = 90
}

local Player = game.Players.LocalPlayer
local Character, Humanoid
local originalWalkSpeed = 16

local isDrinking = false
local drinkBoostEndTime = 0
local originalFOV = 70
local isPhoneOpen = false
local isMusicOpen = false
local currentPaintColor = Color3.fromRGB(255, 0, 0)
local paintSplatsFolder = nil
local maxSplats = 999999
local fovTween = nil

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local isTouchDevice = UserInputService.TouchEnabled

local SOUNDS = {}

local phoneSettings = {
    fpsEnabled = false,
    flashlightEnabled = false,
    joinTime = os.clock()
}

local fpsLabel = nil
local phoneFlashlight = nil

-- Estados de "equipamento" via hotbar (sem Tools)
local equippedItem = nil          -- "BloxyCola" | "TzesPhone" | "Lanterna" | "TzeSprayCan" | nil
local lanternLight = nil          -- SpotLight da lanterna
local sprayState = {              -- estado do spray
    gui = nil,
    particles = nil,
    sound = nil,
    connection = nil,
    isActive = false,
    nozzle = nil
}

local function createSounds()
    for _, sound in pairs(Player:WaitForChild("PlayerGui"):GetChildren()) do
        if sound:IsA("Sound") and (sound.SoundId == "rbxassetid://138475744729338") then
            sound:Destroy()
        end
    end

    SOUNDS.Drink = Instance.new("Sound", Player:WaitForChild("PlayerGui"))
    SOUNDS.Drink.Name = "CustomDrinkSound"
    SOUNDS.Drink.SoundId = "rbxassetid://6811412938"
    SOUNDS.Drink.Volume = 1.0
    SOUNDS.Drink.PlaybackSpeed = 1
    SOUNDS.Drink.Looped = false
end

createSounds()

local function tweenFOV(targetFOV, duration)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if fovTween then
        pcall(function() fovTween:Cancel() end)
        fovTween = nil
    end
    fovTween = TweenService:Create(cam, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
        FieldOfView = targetFOV
    })
    fovTween:Play()
end

local function resetFOV()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if fovTween then
        pcall(function() fovTween:Cancel() end)
        fovTween = nil
    end
    cam.FieldOfView = originalFOV
end

local function cleanup()
    isDrinking = false
    drinkBoostEndTime = 0
    resetFOV()

    if Humanoid then
        Humanoid.JumpPower = SETTINGS.JumpPower
        Humanoid.WalkSpeed = originalWalkSpeed
    end

    if phoneFlashlight then
        phoneFlashlight:Destroy()
        phoneFlashlight = nil
    end

    -- Limpa lanterna e spray ao resetar personagem
    if lanternLight then
        pcall(function() lanternLight:Destroy() end)
        lanternLight = nil
    end
    if sprayState.gui then
        pcall(function() sprayState.gui:Destroy() end)
        sprayState.gui = nil
    end
    if sprayState.connection then
        pcall(function() sprayState.connection:Disconnect() end)
        sprayState.connection = nil
    end
    if sprayState.particles then
        pcall(function() sprayState.particles:Destroy() end)
        sprayState.particles = nil
    end
    if sprayState.sound then
        pcall(function() sprayState.sound:Destroy() end)
        sprayState.sound = nil
    end
    if sprayState.nozzle then
        pcall(function() sprayState.nozzle:Destroy() end)
        sprayState.nozzle = nil
    end
    sprayState.isActive = false
    equippedItem = nil
end

local function removeExtraRoots()
    if not Character then return end
    local mainRoot = Character:FindFirstChild("HumanoidRootPart")
    if not mainRoot then return end
    for _, child in pairs(Character:GetChildren()) do
        if child:IsA("BasePart") and child.Name == "HumanoidRootPart" and child ~= mainRoot then
            pcall(function() child:Destroy() end)
            if child and child.Parent then
                child.Transparency = 1
                child.CanCollide = false
                child.Anchored = false
                child.Massless = true
            end
        end
    end
end

local function updateMovementStats()
    if not Humanoid then return end
    
    local baseSpeed = originalWalkSpeed
    
    if isDrinking then
        baseSpeed = 10
    elseif os.clock() < drinkBoostEndTime then 
        baseSpeed = SETTINGS.BoostSpeed 
    end
    
    Humanoid.WalkSpeed = baseSpeed
    
    local baseJump = SETTINGS.JumpPower
    if os.clock() < drinkBoostEndTime then 
        baseJump = SETTINGS.JumpPower + SETTINGS.BoostJump 
    end
    Humanoid.JumpPower = baseJump
end

-- =========================================================
-- CUSTOM HOTBAR (só os slots selecionados) - SEM TOOLS
-- =========================================================
local HotbarGui = Instance.new("ScreenGui")
HotbarGui.Name = "TzeCustomHotbar"
HotbarGui.ResetOnSpawn = false
HotbarGui.IgnoreGuiInset = true
HotbarGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HotbarGui.Parent = game:GetService("CoreGui")

local HotbarFrame = Instance.new("Frame")
HotbarFrame.Name = "HotbarFrame"
HotbarFrame.Size = UDim2.new(0, 152, 0, 40)
HotbarFrame.Position = UDim2.new(1, -158, 1, -72)
HotbarFrame.BackgroundTransparency = 1
HotbarFrame.Visible = true
HotbarFrame.Parent = HotbarGui

-- Escala adaptativa da Hotbar (maior em dispositivos touch)
local hotbarUIScale = Instance.new("UIScale")
hotbarUIScale.Parent = HotbarFrame
local function updateHotbarScale()
    local cam = Workspace.CurrentCamera
    if cam then
        local size = cam.ViewportSize
        local baseScale = math.clamp(math.min(size.X / 800, size.Y / 500), 0.75, 1.35)
        if isTouchDevice then
            baseScale = math.clamp(baseScale * 1.25, 0.9, 1.6)
        end
        hotbarUIScale.Scale = baseScale
    end
end
updateHotbarScale()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateHotbarScale)
end

local slotsData = {
    {Name = "BloxyCola",  Emoji = "🥤", Color = Color3.fromRGB(255, 70, 70),   ToolName = "BloxyCola"},
    {Name = "TzesPhone",  Emoji = "📱", Color = Color3.fromRGB(50, 205, 50),   ToolName = "TzesPhone"},
    {Name = "Lanterna",   Emoji = "🔦", Color = Color3.fromRGB(255, 200, 50),  ToolName = "Lanterna"},
    {Name = "TzeSprayCan",Emoji = "🎨", Color = Color3.fromRGB(80, 180, 255),  ToolName = "TzeSprayCan"}
}

local slotButtons = {}
local activeSlots = {}

for _, data in ipairs(slotsData) do
    if selectedItems[data.ToolName] then
        table.insert(activeSlots, data)
    end
end

-- =========================================================
-- FUNÇÕES DE ATIVAÇÃO / DESATIVAÇÃO (sem Tools)
-- =========================================================
local closePhone, openPhone, togglePhone

local function unequipAll()
    -- Lanterna
    if lanternLight then
        pcall(function() lanternLight:Destroy() end)
        lanternLight = nil
    end

    -- Spray
    if sprayState.isActive then
        sprayState.isActive = false
        if sprayState.particles then sprayState.particles.Rate = 0 end
        if sprayState.sound then sprayState.sound:Stop() end
        if sprayState.connection then
            pcall(function() sprayState.connection:Disconnect() end)
            sprayState.connection = nil
        end
    end
    if sprayState.gui then
        pcall(function() sprayState.gui:Destroy() end)
        sprayState.gui = nil
    end
    if sprayState.particles then
        pcall(function() sprayState.particles:Destroy() end)
        sprayState.particles = nil
    end
    if sprayState.sound then
        pcall(function() sprayState.sound:Destroy() end)
        sprayState.sound = nil
    end
    if sprayState.nozzle then
        pcall(function() sprayState.nozzle:Destroy() end)
        sprayState.nozzle = nil
    end

    -- Phone (fecha se estiver aberto)
    if isPhoneOpen and closePhone then
        closePhone()
    end

    equippedItem = nil
end

local function activateBloxyCola()
    if isDrinking or (os.clock() < drinkBoostEndTime) or not Humanoid or not Character then return end
    isDrinking = true
    updateMovementStats()
    
    if SOUNDS.Drink then SOUNDS.Drink:Play() end
    
    task.delay(SETTINGS.DrinkDuration, function()
        isDrinking = false
        drinkBoostEndTime = os.clock() + SETTINGS.BoostDuration
        updateMovementStats()
        
        tweenFOV(SETTINGS.BoostFOV, 0.5)
        
        task.delay(SETTINGS.BoostDuration, function()
            if os.clock() >= drinkBoostEndTime then
                drinkBoostEndTime = 0
                updateMovementStats()
                tweenFOV(originalFOV, 0.3)
            end
        end)
    end)
end

local function activateLanterna()
    if not Character then return end
    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if lanternLight then
        pcall(function() lanternLight:Destroy() end)
        lanternLight = nil
    end

    lanternLight = Instance.new("SpotLight")
    lanternLight.Name = "TzeLanternLight"
    lanternLight.Brightness = 4
    lanternLight.Range = 80
    lanternLight.Angle = 60
    lanternLight.Face = Enum.NormalId.Front
    lanternLight.Enabled = true
    lanternLight.Parent = root
end

local function activateSpray()
    if not Character then return end
    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Cria nozzle invisível soldado ao personagem
    local nozzle = Instance.new("Part")
    nozzle.Name = "TzeSprayNozzle"
    nozzle.Size = Vector3.new(0.2, 0.4, 0.2)
    nozzle.Transparency = 1
    nozzle.CanCollide = false
    nozzle.Massless = true
    nozzle.Anchored = false
    nozzle.Parent = Character

    local weld = Instance.new("Weld")
    weld.Part0 = root
    weld.Part1 = nozzle
    weld.C0 = CFrame.new(0, 0.5, -1.2)
    weld.Parent = nozzle

    sprayState.nozzle = nozzle

    local sprayParticles = Instance.new("ParticleEmitter")
    sprayParticles.Name = "SprayParticles"
    sprayParticles.Texture = "rbxassetid://241650885"
    sprayParticles.Color = ColorSequence.new(currentPaintColor)
    sprayParticles.LightEmission = 0.8
    sprayParticles.Rate = 0
    sprayParticles.Lifetime = NumberRange.new(0.3, 0.6)
    sprayParticles.Speed = NumberRange.new(60, 90)
    sprayParticles.SpreadAngle = Vector2.new(15, 15)
    sprayParticles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.1)})
    sprayParticles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    sprayParticles.Parent = nozzle
    sprayState.particles = sprayParticles

    local spraySound = Instance.new("Sound")
    spraySound.Name = "SpraySound"
    spraySound.SoundId = "rbxassetid://135953747985183"
    spraySound.Volume = 0.85
    spraySound.Looped = true
    spraySound.Parent = nozzle
    sprayState.sound = spraySound

    -- GUI do spray
    local sprayGui = Instance.new("ScreenGui")
    sprayGui.Name = "SprayGui"
    sprayGui.ResetOnSpawn = false
    sprayGui.IgnoreGuiInset = true
    sprayGui.Parent = Player.PlayerGui
    sprayState.gui = sprayGui

    local sprayUIScale = Instance.new("UIScale")
    sprayUIScale.Parent = sprayGui
    local function updateSprayScale()
        local cam = Workspace.CurrentCamera
        if cam then
            local size = cam.ViewportSize
            local scale = math.clamp(math.min(size.X / 700, size.Y / 500), 0.7, 1.4)
            if isTouchDevice then
                scale = math.clamp(scale * 1.15, 0.85, 1.5)
            end
            sprayUIScale.Scale = scale
        end
    end
    updateSprayScale()
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSprayScale)
    end

    -- REMOVIDO: overlay preto atrás dos botões

    local crosshair = Instance.new("Frame")
    crosshair.Size = UDim2.new(0, 4, 0, 4)
    crosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
    crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    crosshair.BorderSizePixel = 0
    crosshair.BackgroundTransparency = 0.2
    crosshair.Parent = sprayGui
    
    local crosshairRing = Instance.new("Frame")
    crosshairRing.Size = UDim2.new(0, 24, 0, 24)
    crosshairRing.Position = UDim2.new(0.5, -12, 0.5, -12)
    crosshairRing.BackgroundTransparency = 1
    crosshairRing.BorderSizePixel = 2
    crosshairRing.BorderColor3 = Color3.fromRGB(255, 255, 255)
    crosshairRing.Parent = sprayGui
    Instance.new("UICorner", crosshairRing).CornerRadius = UDim.new(1, 0)

    -- Botões mais próximos entre si
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(0, 90, 0, 230)
    buttonContainer.Position = UDim2.new(0, 20, 1, -250)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = sprayGui

    local sprayBtn = Instance.new("TextButton")
    sprayBtn.Size = UDim2.new(0, 80, 0, 80)
    sprayBtn.Position = UDim2.new(0, 5, 0, 0)
    sprayBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    sprayBtn.Text = "💨"
    sprayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sprayBtn.TextSize = 48
    sprayBtn.Font = Enum.Font.GothamBold
    sprayBtn.Parent = buttonContainer
    Instance.new("UICorner", sprayBtn).CornerRadius = UDim.new(1, 0)
    
    local holdLabel = Instance.new("TextLabel")
    holdLabel.Size = UDim2.new(1, 0, 0, 20)
    holdLabel.Position = UDim2.new(0, 0, 1, -24)
    holdLabel.BackgroundTransparency = 1
    holdLabel.Text = "SEGURAR"
    holdLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    holdLabel.Font = Enum.Font.GothamBold
    holdLabel.TextSize = 12
    holdLabel.Parent = sprayBtn

    local colorBtn = Instance.new("TextButton")
    colorBtn.Size = UDim2.new(0, 64, 0, 64)
    colorBtn.Position = UDim2.new(0, 13, 0, 90)
    colorBtn.BackgroundColor3 = currentPaintColor
    colorBtn.Text = "🎨"
    colorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    colorBtn.TextSize = 32
    colorBtn.Font = Enum.Font.GothamBold
    colorBtn.Parent = buttonContainer
    Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(1, 0)

    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 64, 0, 64)
    clearBtn.Position = UDim2.new(0, 13, 0, 164)
    clearBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    clearBtn.Text = "🗑️"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 32
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.Parent = buttonContainer
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(1, 0)

    local colorPicker = Instance.new("Frame")
    colorPicker.Size = UDim2.new(0, 320, 0, 380)
    colorPicker.Position = UDim2.new(0.5, -160, 0.5, -190)
    colorPicker.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    colorPicker.BackgroundTransparency = 0.1
    colorPicker.BorderSizePixel = 0
    colorPicker.Visible = false
    colorPicker.Parent = sprayGui
    Instance.new("UICorner", colorPicker).CornerRadius = UDim.new(0, 20)
    
    local pickerStroke = Instance.new("UIStroke")
    pickerStroke.Color = Color3.fromRGB(70, 70, 80)
    pickerStroke.Thickness = 2
    pickerStroke.Parent = colorPicker
    
    local pickerTitle = Instance.new("TextLabel")
    pickerTitle.Size = UDim2.new(1, 0, 0, 50)
    pickerTitle.BackgroundTransparency = 1
    pickerTitle.Text = "🎨 SELECIONE A COR"
    pickerTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
    pickerTitle.Font = Enum.Font.GothamBold
    pickerTitle.TextSize = 16
    pickerTitle.Parent = colorPicker
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -70)
    scroll.Position = UDim2.new(0, 10, 0, 60)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
    scroll.Parent = colorPicker
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 54, 0, 54)
    gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.Parent = scroll
    
    local colors = {
        Color3.fromRGB(255, 59, 48), Color3.fromRGB(255, 149, 0), Color3.fromRGB(255, 204, 0),
        Color3.fromRGB(52, 199, 89), Color3.fromRGB(0, 199, 190), Color3.fromRGB(0, 122, 255),
        Color3.fromRGB(88, 86, 214), Color3.fromRGB(175, 82, 222), Color3.fromRGB(255, 45, 85),
        Color3.fromRGB(255, 159, 10), Color3.fromRGB(48, 176, 50), Color3.fromRGB(90, 200, 250),
        Color3.fromRGB(100, 100, 255), Color3.fromRGB(200, 70, 200), Color3.fromRGB(255, 100, 130),
        Color3.fromRGB(255, 180, 50), Color3.fromRGB(80, 220, 100), Color3.fromRGB(50, 150, 255),
        Color3.fromRGB(150, 80, 220), Color3.fromRGB(255, 80, 120), Color3.fromRGB(200, 200, 200),
        Color3.fromRGB(80, 80, 80), Color3.fromRGB(0, 0, 0), Color3.fromRGB(255, 255, 255)
    }
    
    for _, col in ipairs(colors) do
        local cBtn = Instance.new("TextButton")
        cBtn.BackgroundColor3 = col
        cBtn.Text = ""
        cBtn.Parent = scroll
        Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 12)
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(50, 50, 55)
        stroke.Thickness = 1.5
        stroke.Parent = cBtn
        
        cBtn.MouseButton1Click:Connect(function()
            currentPaintColor = col
            if sprayState.particles then
                sprayState.particles.Color = ColorSequence.new(col)
            end
            colorBtn.BackgroundColor3 = col
            local closeTween = TweenService:Create(colorPicker, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
            closeTween:Play()
            closeTween.Completed:Connect(function()
                colorPicker.Visible = false
                colorPicker.BackgroundTransparency = 0.1
            end)
        end)
    end
    
    local function showColorPicker()
        colorPicker.Visible = true
        colorPicker.BackgroundTransparency = 0.1
        local openTween = TweenService:Create(colorPicker, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -160, 0.5, -190)})
        openTween:Play()
        task.wait(0.05)
        scroll.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end
    
    local function startSprayingHold()
        if sprayState.isActive then return end
        sprayState.isActive = true
        if sprayState.particles then sprayState.particles.Rate = 140 end
        if sprayState.sound then sprayState.sound:Play() end
        sprayBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        holdLabel.Text = "ATIVO"
        
        if sprayState.connection then sprayState.connection:Disconnect() end
        sprayState.connection = RunService.Heartbeat:Connect(function()
            if not sprayState.isActive or not Character then return end
            
            local camera = Workspace.CurrentCamera
            local ray = camera:ViewportPointToRay(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {Character}
            if paintSplatsFolder then
                table.insert(raycastParams.FilterDescendantsInstances, paintSplatsFolder)
            end
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            
            local result = Workspace:Raycast(ray.Origin, ray.Direction * 300, raycastParams)
            if result and result.Instance then
                if paintSplatsFolder then
                    for _, existing in pairs(paintSplatsFolder:GetChildren()) do
                        if existing:IsA("BasePart") then
                            if (existing.Position - result.Position).Magnitude < 0.18 then
                                return
                            end
                        end
                    end
                end

                if not paintSplatsFolder then
                    paintSplatsFolder = Instance.new("Folder")
                    paintSplatsFolder.Name = "TzePaintSplats"
                    paintSplatsFolder.Parent = Workspace
                end
                
                local hitPos = result.Position + result.Normal * 0.04
                local normal = result.Normal
                local right = normal:Cross(Vector3.new(0,1,0))
                if right.Magnitude < 0.01 then right = normal:Cross(Vector3.new(1,0,0)) end
                right = right.Unit
                
                local splat = Instance.new("Part")
                splat.Size = Vector3.new(0.22 + math.random() * 0.18, 0.05, 0.22 + math.random() * 0.18)
                splat.Color = currentPaintColor
                splat.Material = Enum.Material.SmoothPlastic
                splat.Anchored = true
                splat.CanCollide = false
                splat.CFrame = CFrame.new(hitPos) * CFrame.fromMatrix(Vector3.new(0,0,0), right, normal) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
                splat.Parent = paintSplatsFolder
            end
        end)
    end
    
    local function stopSprayingHold()
        if not sprayState.isActive then return end
        sprayState.isActive = false
        if sprayState.particles then sprayState.particles.Rate = 0 end
        if sprayState.sound then sprayState.sound:Stop() end
        if sprayState.connection then
            sprayState.connection:Disconnect()
            sprayState.connection = nil
        end
        sprayBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        holdLabel.Text = "SEGURAR"
    end
    
    sprayBtn.MouseButton1Down:Connect(startSprayingHold)
    sprayBtn.MouseButton1Up:Connect(stopSprayingHold)
    sprayBtn.MouseLeave:Connect(stopSprayingHold)
    
    colorBtn.MouseButton1Click:Connect(showColorPicker)
    
    clearBtn.MouseButton1Click:Connect(function()
        if paintSplatsFolder then
            paintSplatsFolder:ClearAllChildren()
        end
        local origColor = clearBtn.BackgroundColor3
        clearBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        task.wait(0.1)
        clearBtn.BackgroundColor3 = origColor
    end)
    
    TweenService:Create(buttonContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 20, 1, -250)}):Play()
end

local function equipItem(toolName)
    if equippedItem == toolName then
        -- Já está equipado → desequipa
        unequipAll()
        return
    end

    -- Desequipa o anterior
    unequipAll()

    equippedItem = toolName

    if toolName == "BloxyCola" then
        activateBloxyCola()
        -- Cola é uso único, já desequipa depois do uso
        task.delay(0.1, function()
            if equippedItem == "BloxyCola" then
                equippedItem = nil
            end
        end)
    elseif toolName == "TzesPhone" then
        if togglePhone then
            togglePhone()
        end
    elseif toolName == "Lanterna" then
        activateLanterna()
    elseif toolName == "TzeSprayCan" then
        activateSpray()
    end
end

local function createSlot(index, data)
    local slot = Instance.new("TextButton")
    slot.Name = "Slot_" .. data.ToolName
    slot.Size = UDim2.new(0, 32, 0, 32)
    slot.Position = UDim2.new(0, (index-1) * 38, 0, 4)
    slot.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    slot.BorderSizePixel = 0
    slot.Text = ""
    slot.AutoButtonColor = false
    slot.Parent = HotbarFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = slot

    local stroke = Instance.new("UIStroke")
    stroke.Color = data.Color
    stroke.Thickness = 2.5
    stroke.Parent = slot

    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.Position = UDim2.new(0, 2, 0, 2)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.55
    shadow.ZIndex = slot.ZIndex - 1
    shadow.Parent = slot
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 10)

    local emoji = Instance.new("TextLabel")
    emoji.Size = UDim2.new(1, 0, 1, 0)
    emoji.BackgroundTransparency = 1
    emoji.Text = data.Emoji
    emoji.TextSize = 18
    emoji.Parent = slot

    local selected = Instance.new("Frame")
    selected.Name = "Selected"
    selected.Size = UDim2.new(1, 0, 1, 0)
    selected.Position = UDim2.new(0, 0, 0, 0)
    selected.BackgroundTransparency = 1
    selected.BorderSizePixel = 0
    selected.Visible = false
    selected.Parent = slot

    local selStroke = Instance.new("UIStroke")
    selStroke.Color = Color3.fromRGB(255, 255, 255)
    selStroke.Thickness = 2.5
    selStroke.Parent = selected
    Instance.new("UICorner", selected).CornerRadius = UDim.new(0, 10)

    slot.MouseEnter:Connect(function()
        TweenService:Create(slot, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(42, 42, 52),
            Size = UDim2.new(0, 34, 0, 34)
        }):Play()
    end)

    slot.MouseLeave:Connect(function()
        TweenService:Create(slot, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(28, 28, 36),
            Size = UDim2.new(0, 32, 0, 32)
        }):Play()
    end)

    slot.MouseButton1Click:Connect(function()
        equipItem(data.ToolName)
    end)

    slotButtons[data.ToolName] = {button = slot, selected = selected, data = data}
    return slot
end

for i, data in ipairs(activeSlots) do
    createSlot(i, data)
end

if #activeSlots > 0 then
    HotbarFrame.Size = UDim2.new(0, (#activeSlots * 38) + 4, 0, 40)
    HotbarFrame.Position = UDim2.new(1, -((#activeSlots * 38) + 10), 1, -72)
else
    HotbarFrame.Visible = false
end

local function updateHotbarSelection()
    for toolName, info in pairs(slotButtons) do
        info.selected.Visible = (equippedItem == toolName)
    end
end

task.spawn(function()
    while true do
        updateHotbarSelection()
        task.wait(0.15)
    end
end)

-- =========================================================
-- TZE PHONE SYSTEM + MUSIC + CRONÔMETRO + CONFIG + GALERIA
-- (só é criado se o Phone foi selecionado)
-- =========================================================
if selectedItems.TzesPhone then
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("TzeMusicSystem") then CoreGui.TzeMusicSystem:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TzeMusicSystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Escala adaptativa do Phone para todos os dispositivos (PC, Mobile, Tablet, Console)
local phoneUIScale = Instance.new("UIScale")
phoneUIScale.Parent = ScreenGui
local function updatePhoneScale()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local size = cam.ViewportSize
    local scale = math.clamp(math.min(size.X / 380, size.Y / 620), 0.55, 1.25)
    if isTouchDevice then
        scale = math.clamp(scale * 1.05, 0.6, 1.35)
    end
    phoneUIScale.Scale = scale
end
updatePhoneScale()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePhoneScale)
end
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        updatePhoneScale()
        task.wait(1)
    end
end)

local currentSound = nil
local isPaused = false
local currentMode = "File"
local mp3List = {}
local filteredList = {}
local currentTrackIndex = 0
local shuffleMode = false
local repeatMode = false
local currentVolume = 1
isMusicOpen = false
isPhoneOpen = false
local currentApp = "home"

-- Galeria
local photoList = {}
local filteredPhotoList = {}
local isInPhotoViewer = false
local currentPhotoIndex = 0

local function createNavBar(parent)
    local navBar = Instance.new("Frame")
    navBar.Name = "NavBar"
    navBar.Size = UDim2.new(1, -20, 0, 30)
    navBar.Position = UDim2.new(0, 10, 1, -38)
    navBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    navBar.BackgroundTransparency = 0.4
    navBar.BorderSizePixel = 0
    navBar.ZIndex = 20
    navBar.Parent = parent
    Instance.new("UICorner", navBar).CornerRadius = UDim.new(0, 14)

    -- ◀  um pouco mais para a DIREITA
    local backBtn = Instance.new("TextButton")
    backBtn.Name = "BackBtn"
    backBtn.Size = UDim2.new(0, 28, 0, 28)
    backBtn.Position = UDim2.new(0, 22, 0.5, -14)
    backBtn.BackgroundTransparency = 1
    backBtn.Text = "◀"
    backBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    backBtn.TextSize = 20
    backBtn.Font = Enum.Font.GothamBold
    backBtn.ZIndex = 21
    backBtn.Parent = navBar

    -- ◯  fica no MEIO
    local homeBtn = Instance.new("TextButton")
    homeBtn.Name = "HomeCircle"
    homeBtn.Size = UDim2.new(0, 28, 0, 28)
    homeBtn.Position = UDim2.new(0.5, -14, 0.5, -14)
    homeBtn.BackgroundTransparency = 1
    homeBtn.Text = "◯"
    homeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    homeBtn.TextSize = 22
    homeBtn.Font = Enum.Font.GothamBold
    homeBtn.ZIndex = 21
    homeBtn.Parent = navBar

    local function addClickAnim(btn)
        btn.MouseButton1Down:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextSize = btn.TextSize - 4
            }):Play()
        end)
        btn.MouseButton1Up:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                TextSize = (btn.Name == "BackBtn") and 20 or 22
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {
                TextSize = (btn.Name == "BackBtn") and 20 or 22
            }):Play()
        end)
    end
    addClickAnim(backBtn)
    addClickAnim(homeBtn)

    return homeBtn, backBtn
end

-- ========== PHONE HOME SCREEN (posicionado à DIREITA) ==========
local PhoneHome = Instance.new("Frame")
PhoneHome.Name = "PhoneHome"
PhoneHome.Size = UDim2.new(0, 280, 0, 440)
PhoneHome.Position = UDim2.new(1, -300, 0.5, -220)
PhoneHome.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
PhoneHome.BorderSizePixel = 0
PhoneHome.Visible = false
PhoneHome.Active = true
PhoneHome.Draggable = true
PhoneHome.Parent = ScreenGui

Instance.new("UICorner", PhoneHome).CornerRadius = UDim.new(0, 28)

local homeBezel = Instance.new("UIStroke")
homeBezel.Color = Color3.fromRGB(50, 205, 50)
homeBezel.Thickness = 6
homeBezel.Parent = PhoneHome

local homeBg = Instance.new("ImageLabel")
homeBg.Name = "Wallpaper"
homeBg.Size = UDim2.new(1, 0, 1, 0)
homeBg.BackgroundTransparency = 1
homeBg.Image = "rbxassetid://12506271392"
homeBg.ScaleType = Enum.ScaleType.Crop
homeBg.ZIndex = 1
homeBg.Parent = PhoneHome
Instance.new("UICorner", homeBg).CornerRadius = UDim.new(0, 28)

local homeOverlay = Instance.new("Frame")
homeOverlay.Size = UDim2.new(1, 0, 1, 0)
homeOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
homeOverlay.BackgroundTransparency = 0.45
homeOverlay.BorderSizePixel = 0
homeOverlay.ZIndex = 2
homeOverlay.Parent = PhoneHome
Instance.new("UICorner", homeOverlay).CornerRadius = UDim.new(0, 28)

local homeEars = Instance.new("ImageLabel")
homeEars.Name = "EarsDecoration"
homeEars.Size = UDim2.new(0, 340, 0, 95)
homeEars.Position = UDim2.new(0.5, -170, 0, -48)
homeEars.BackgroundTransparency = 1
homeEars.Image = "rbxassetid://108135642658853"
homeEars.ImageColor3 = Color3.fromRGB(50, 205, 50)
homeEars.ZIndex = 10
homeEars.Parent = PhoneHome

local homeNotch = Instance.new("Frame")
homeNotch.Size = UDim2.new(0, 82, 0, 24)
homeNotch.Position = UDim2.new(0.5, -41, 0, 9)
homeNotch.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
homeNotch.BorderSizePixel = 0
homeNotch.ZIndex = 5
homeNotch.Parent = PhoneHome
Instance.new("UICorner", homeNotch).CornerRadius = UDim.new(1, 0)

local homeCamDot = Instance.new("Frame")
homeCamDot.Size = UDim2.new(0, 10, 0, 10)
homeCamDot.Position = UDim2.new(0.5, -55, 0, 13)
homeCamDot.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
homeCamDot.BorderSizePixel = 0
homeCamDot.ZIndex = 6
homeCamDot.Parent = PhoneHome
Instance.new("UICorner", homeCamDot).CornerRadius = UDim.new(1, 0)

local homeStatus = Instance.new("TextLabel")
homeStatus.Name = "StatusClock"
homeStatus.Size = UDim2.new(0.5, -10, 0, 22)
homeStatus.Position = UDim2.new(0, 20, 0, 40)
homeStatus.BackgroundTransparency = 1
homeStatus.Text = os.date("%H:%M")
homeStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
homeStatus.Font = Enum.Font.GothamBold
homeStatus.TextSize = 14
homeStatus.TextXAlignment = Enum.TextXAlignment.Left
homeStatus.ZIndex = 5
homeStatus.Parent = PhoneHome

fpsLabel = Instance.new("TextLabel")
fpsLabel.Name = "FPSLabel"
fpsLabel.Size = UDim2.new(0.5, -10, 0, 22)
fpsLabel.Position = UDim2.new(0.5, 0, 0, 40)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: --"
fpsLabel.TextColor3 = Color3.fromRGB(50, 205, 50)
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 13
fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
fpsLabel.Visible = false
fpsLabel.ZIndex = 5
fpsLabel.Parent = PhoneHome

local homeTitle = Instance.new("TextLabel")
homeTitle.Size = UDim2.new(1, 0, 0, 30)
homeTitle.Position = UDim2.new(0, 0, 0, 70)
homeTitle.BackgroundTransparency = 1
homeTitle.Text = "Apps"
homeTitle.TextColor3 = Color3.new(1, 1, 1)
homeTitle.Font = Enum.Font.GothamBold
homeTitle.TextSize = 22
homeTitle.ZIndex = 5
homeTitle.Parent = PhoneHome

local appsContainer = Instance.new("Frame")
appsContainer.Size = UDim2.new(1, -40, 0, 220)
appsContainer.Position = UDim2.new(0, 20, 0, 110)
appsContainer.BackgroundTransparency = 1
appsContainer.ZIndex = 5
appsContainer.Parent = PhoneHome

local function createAppIcon(name, emoji, color, pos)
    local icon = Instance.new("TextButton")
    icon.Size = UDim2.new(0, 70, 0, 90)
    icon.Position = pos
    icon.BackgroundTransparency = 1
    icon.Text = ""
    icon.ZIndex = 6
    icon.Parent = appsContainer

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 64, 0, 64)
    bg.Position = UDim2.new(0.5, -32, 0, 0)
    bg.BackgroundColor3 = color
    bg.BorderSizePixel = 0
    bg.ZIndex = 6
    bg.Parent = icon
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 16)

    local emojiLabel = Instance.new("TextLabel")
    emojiLabel.Size = UDim2.new(1, 0, 1, 0)
    emojiLabel.BackgroundTransparency = 1
    emojiLabel.Text = emoji
    emojiLabel.TextSize = 28
    emojiLabel.ZIndex = 7
    emojiLabel.Parent = bg

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 1, -22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 11
    nameLabel.ZIndex = 7
    nameLabel.Parent = icon

    return icon
end

local MusicAppIcon = createAppIcon("Música", "🎵", Color3.fromRGB(0, 180, 255), UDim2.new(0, 5, 0, 0))
local StopwatchAppIcon = createAppIcon("Cronômetro", "⏱️", Color3.fromRGB(255, 140, 30), UDim2.new(0, 85, 0, 0))
local ConfigAppIcon = createAppIcon("Config", "⚙️", Color3.fromRGB(120, 120, 130), UDim2.new(0, 165, 0, 0))
local GalleryAppIcon = createAppIcon("Galeria", "🖼️", Color3.fromRGB(180, 80, 220), UDim2.new(0, 5, 0, 100))

local homeNavBtn, homeBackBtn = createNavBar(PhoneHome)

local frameCount = 0
local lastFpsUpdate = os.clock()
local currentFps = 0

task.spawn(function()
    while true do
        if homeStatus and homeStatus.Parent then
            homeStatus.Text = os.date("%H:%M")
        end
        task.wait(1)
    end
end)

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = os.clock()
    if now - lastFpsUpdate >= 0.5 then
        currentFps = math.floor(frameCount / (now - lastFpsUpdate))
        frameCount = 0
        lastFpsUpdate = now
        if fpsLabel and phoneSettings.fpsEnabled then
            fpsLabel.Text = "FPS: " .. currentFps
            fpsLabel.Visible = true
        elseif fpsLabel then
            fpsLabel.Visible = false
        end
    end
end)

-- ========== VOLUME FIXO ==========
local VolumeFrame = Instance.new("Frame")
VolumeFrame.Name = "VolumeFrame"
VolumeFrame.Size = UDim2.new(0, 28, 0, 110)
VolumeFrame.Position = UDim2.new(0, -34, 0.5, -55)
VolumeFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
VolumeFrame.BackgroundTransparency = 0.15
VolumeFrame.BorderSizePixel = 0
VolumeFrame.ZIndex = 30
VolumeFrame.Visible = false
VolumeFrame.Parent = ScreenGui
Instance.new("UICorner", VolumeFrame).CornerRadius = UDim.new(0, 10)
local volFrameStroke = Instance.new("UIStroke")
volFrameStroke.Color = Color3.fromRGB(50, 205, 50)
volFrameStroke.Thickness = 1.2
volFrameStroke.Parent = VolumeFrame

local VolUpBtn = Instance.new("TextButton")
VolUpBtn.Name = "VolUp"
VolUpBtn.Size = UDim2.new(1, -4, 0, 48)
VolUpBtn.Position = UDim2.new(0, 2, 0, 4)
VolUpBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
VolUpBtn.Text = "🔊"
VolUpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VolUpBtn.Font = Enum.Font.GothamBold
VolUpBtn.TextSize = 16
VolUpBtn.ZIndex = 31
VolUpBtn.Parent = VolumeFrame
Instance.new("UICorner", VolUpBtn).CornerRadius = UDim.new(0, 8)
local volUpStroke = Instance.new("UIStroke")
volUpStroke.Color = Color3.fromRGB(50, 205, 50)
volUpStroke.Thickness = 1
volUpStroke.Parent = VolUpBtn

local VolDownBtn = Instance.new("TextButton")
VolDownBtn.Name = "VolDown"
VolDownBtn.Size = UDim2.new(1, -4, 0, 48)
VolDownBtn.Position = UDim2.new(0, 2, 0, 58)
VolDownBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
VolDownBtn.Text = "🔉"
VolDownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VolDownBtn.Font = Enum.Font.GothamBold
VolDownBtn.TextSize = 16
VolDownBtn.ZIndex = 31
VolDownBtn.Parent = VolumeFrame
Instance.new("UICorner", VolDownBtn).CornerRadius = UDim.new(0, 8)
local volDownStroke = Instance.new("UIStroke")
volDownStroke.Color = Color3.fromRGB(50, 205, 50)
volDownStroke.Thickness = 1
volDownStroke.Parent = VolDownBtn

VolUpBtn.MouseButton1Click:Connect(function()
    currentVolume = math.clamp(currentVolume + 0.1, 0, 1)
    if currentSound then
        currentSound.Volume = currentVolume
    end
end)

VolDownBtn.MouseButton1Click:Connect(function()
    currentVolume = math.clamp(currentVolume - 0.1, 0, 1)
    if currentSound then
        currentSound.Volume = currentVolume
    end
end)

local function attachVolumeTo(frame)
    if not frame then return end
    VolumeFrame.Parent = frame
    VolumeFrame.Position = UDim2.new(0, -34, 0.5, -55)
    VolumeFrame.Visible = true
end

-- ========== MUSIC PLAYER (direita) ==========
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 440)
MainFrame.Position = UDim2.new(1, -300, 0.5, -220)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 28)

local bezelStroke = Instance.new("UIStroke")
bezelStroke.Color = Color3.fromRGB(50, 205, 50)
bezelStroke.Thickness = 6
bezelStroke.Parent = MainFrame

local earsImage = Instance.new("ImageLabel")
earsImage.Name = "EarsDecoration"
earsImage.Size = UDim2.new(0, 340, 0, 95)
earsImage.Position = UDim2.new(0.5, -170, 0, -48)
earsImage.BackgroundTransparency = 1
earsImage.Image = "rbxassetid://108135642658853"
earsImage.ImageColor3 = Color3.fromRGB(50, 205, 50)
earsImage.ZIndex = MainFrame.ZIndex + 2
earsImage.Parent = MainFrame

local notch = Instance.new("Frame")
notch.Size = UDim2.new(0, 82, 0, 24)
notch.Position = UDim2.new(0.5, -41, 0, 9)
notch.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
notch.BorderSizePixel = 0
notch.Parent = MainFrame
Instance.new("UICorner", notch).CornerRadius = UDim.new(1, 0)

local cameraDot = Instance.new("Frame")
cameraDot.Size = UDim2.new(0, 10, 0, 10)
cameraDot.Position = UDim2.new(0.5, -55, 0, 13)
cameraDot.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
cameraDot.BorderSizePixel = 0
cameraDot.Parent = MainFrame
Instance.new("UICorner", cameraDot).CornerRadius = UDim.new(1, 0)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.Position = UDim2.new(0, 0, 0, 38)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0, 110, 0, 28)
ModeBtn.Position = UDim2.new(1, -122, 0.5, -14)
ModeBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
ModeBtn.Text = "Arquivo"
ModeBtn.TextColor3 = Color3.fromRGB(50, 205, 50)
ModeBtn.Font = Enum.Font.GothamBold
ModeBtn.TextSize = 12
ModeBtn.Parent = TopBar
Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 10)
local modeStroke = Instance.new("UIStroke")
modeStroke.Color = Color3.fromRGB(50, 205, 50)
modeStroke.Thickness = 1.2
modeStroke.Parent = ModeBtn

local MusicTitle = Instance.new("TextLabel")
MusicTitle.Size = UDim2.new(0, 120, 0, 28)
MusicTitle.Position = UDim2.new(0, 16, 0.5, -14)
MusicTitle.BackgroundTransparency = 1
MusicTitle.Text = "Música"
MusicTitle.TextColor3 = Color3.new(1, 1, 1)
MusicTitle.Font = Enum.Font.GothamBold
MusicTitle.TextSize = 18
MusicTitle.TextXAlignment = Enum.TextXAlignment.Left
MusicTitle.Parent = TopBar
local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(50, 205, 50)
titleStroke.Thickness = 1
titleStroke.Parent = MusicTitle

local NowPlayingCard = Instance.new("Frame")
NowPlayingCard.Size = UDim2.new(1, -24, 0, 118)
NowPlayingCard.Position = UDim2.new(0, 12, 0, 88)
NowPlayingCard.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
NowPlayingCard.BorderSizePixel = 0
NowPlayingCard.Parent = MainFrame
Instance.new("UICorner", NowPlayingCard).CornerRadius = UDim.new(0, 16)
local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(50, 205, 50)
cardStroke.Thickness = 1.2
cardStroke.Parent = NowPlayingCard

local AlbumArt = Instance.new("Frame")
AlbumArt.Size = UDim2.new(0, 56, 0, 56)
AlbumArt.Position = UDim2.new(0, 14, 0.5, -28)
AlbumArt.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
AlbumArt.BorderSizePixel = 0
AlbumArt.Parent = NowPlayingCard
Instance.new("UICorner", AlbumArt).CornerRadius = UDim.new(0, 12)
local artStroke = Instance.new("UIStroke")
artStroke.Color = Color3.fromRGB(40, 160, 40)
artStroke.Thickness = 1.2
artStroke.Parent = AlbumArt

local AlbumIcon = Instance.new("TextLabel")
AlbumIcon.Size = UDim2.new(1, 0, 1, 0)
AlbumIcon.BackgroundTransparency = 1
AlbumIcon.Text = "🎵"
AlbumIcon.TextSize = 28
AlbumIcon.Parent = AlbumArt

local TrackName = Instance.new("TextLabel")
TrackName.Size = UDim2.new(1, -90, 0, 24)
TrackName.Position = UDim2.new(0, 82, 0, 18)
TrackName.BackgroundTransparency = 1
TrackName.Text = "Nenhuma música"
TrackName.TextColor3 = Color3.new(1, 1, 1)
TrackName.Font = Enum.Font.GothamBold
TrackName.TextSize = 15
TrackName.TextXAlignment = Enum.TextXAlignment.Left
TrackName.TextTruncate = Enum.TextTruncate.AtEnd
TrackName.Parent = NowPlayingCard
local trackNameStroke = Instance.new("UIStroke")
trackNameStroke.Color = Color3.fromRGB(50, 205, 50)
trackNameStroke.Thickness = 1
trackNameStroke.Parent = TrackName

local TrackSub = Instance.new("TextLabel")
TrackSub.Size = UDim2.new(1, -90, 0, 18)
TrackSub.Position = UDim2.new(0, 82, 0, 42)
TrackSub.BackgroundTransparency = 1
TrackSub.Text = "Toque para ouvir"
TrackSub.TextColor3 = Color3.fromRGB(140, 140, 155)
TrackSub.Font = Enum.Font.Gotham
TrackSub.TextSize = 12
TrackSub.TextXAlignment = Enum.TextXAlignment.Left
TrackSub.Parent = NowPlayingCard
local trackSubStroke = Instance.new("UIStroke")
trackSubStroke.Color = Color3.fromRGB(50, 205, 50)
trackSubStroke.Thickness = 0.8
trackSubStroke.Parent = TrackSub

local TimeBarBG = Instance.new("Frame")
TimeBarBG.Size = UDim2.new(1, -28, 0, 4)
TimeBarBG.Position = UDim2.new(0, 14, 1, -28)
TimeBarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
TimeBarBG.BorderSizePixel = 0
TimeBarBG.Parent = NowPlayingCard
Instance.new("UICorner", TimeBarBG).CornerRadius = UDim.new(1, 0)

local TimeBarFill = Instance.new("Frame")
TimeBarFill.Size = UDim2.new(0, 0, 1, 0)
TimeBarFill.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
TimeBarFill.BorderSizePixel = 0
TimeBarFill.Parent = TimeBarBG
Instance.new("UICorner", TimeBarFill).CornerRadius = UDim.new(1, 0)

local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(1, -28, 0, 14)
TimeLabel.Position = UDim2.new(0, 14, 1, -18)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "00:00 / 00:00"
TimeLabel.TextColor3 = Color3.fromRGB(130, 130, 145)
TimeLabel.Font = Enum.Font.Code
TimeLabel.TextSize = 10
TimeLabel.TextXAlignment = Enum.TextXAlignment.Right
TimeLabel.Parent = NowPlayingCard
local timeLabelStroke = Instance.new("UIStroke")
timeLabelStroke.Color = Color3.fromRGB(50, 205, 50)
timeLabelStroke.Thickness = 0.8
timeLabelStroke.Parent = TimeLabel

local Controls = Instance.new("Frame")
Controls.Size = UDim2.new(1, -24, 0, 52)
Controls.Position = UDim2.new(0, 12, 0, 218)
Controls.BackgroundTransparency = 1
Controls.Parent = MainFrame

local function createBtn(text, pos, size)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.Parent = Controls
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(50, 205, 50)
    btnStroke.Thickness = 1.2
    btnStroke.Parent = btn
    return btn
end

local ShuffleBtn = createBtn("🔀", UDim2.new(0, 0, 0.5, -18), UDim2.new(0, 42, 0, 36))
local PrevBtn = createBtn("⏮", UDim2.new(0.22, -8, 0.5, -18), UDim2.new(0, 46, 0, 36))
local PlayBtn = createBtn("▶", UDim2.new(0.5, -24, 0.5, -22), UDim2.new(0, 48, 0, 44))
PlayBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
PlayBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
local NextBtn = createBtn("⏭", UDim2.new(0.78, -38, 0.5, -18), UDim2.new(0, 46, 0, 36))
local RepeatBtn = createBtn("🔁", UDim2.new(1, -42, 0.5, -18), UDim2.new(0, 42, 0, 36))

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -24, 0, 32)
SearchBox.Position = UDim2.new(0, 12, 0, 278)
SearchBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
SearchBox.PlaceholderText = "🔍 Pesquisar música..."
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.new(1, 1, 1)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 13
SearchBox.Parent = MainFrame
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 10)
local searchStroke = Instance.new("UIStroke")
searchStroke.Color = Color3.fromRGB(50, 205, 50)
searchStroke.Thickness = 1.2
searchStroke.Parent = SearchBox

local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Size = UDim2.new(1, -24, 0, 90)
ScrollList.Position = UDim2.new(0, 12, 0, 318)
ScrollList.BackgroundTransparency = 1
ScrollList.ScrollBarThickness = 3
ScrollList.ScrollBarImageColor3 = Color3.fromRGB(50, 205, 50)
ScrollList.Parent = MainFrame
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = ScrollList

local IDInput = Instance.new("TextBox")
IDInput.Size = UDim2.new(1, -24, 0, 34)
IDInput.Position = UDim2.new(0, 12, 0, 318)
IDInput.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
IDInput.PlaceholderText = "Digite o Sound ID do Roblox..."
IDInput.Text = ""
IDInput.TextColor3 = Color3.new(1, 1, 1)
IDInput.Visible = false
IDInput.Parent = MainFrame
Instance.new("UICorner", IDInput).CornerRadius = UDim.new(0, 10)
local idStroke = Instance.new("UIStroke")
idStroke.Color = Color3.fromRGB(50, 205, 50)
idStroke.Thickness = 1.2
idStroke.Parent = IDInput

local musicNavBtn, musicBackBtn = createNavBar(MainFrame)

local function formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

local function stopSound()
    if currentSound then
        currentSound:Stop()
        currentSound:Destroy()
        currentSound = nil
    end
end

local function play(id, name, index)
    stopSound()
    currentTrackIndex = index or 0
    currentSound = Instance.new("Sound", MainFrame)
    currentSound.SoundId = id
    currentSound.Volume = currentVolume
    currentSound:Play()
    TrackName.Text = name
    TrackSub.Text = "Tocando agora"
    PlayBtn.Text = "⏸"
    isPaused = false

    currentSound.Ended:Connect(function()
        if not currentSound then return end
        if repeatMode then
            currentSound.TimePosition = 0
            currentSound:Play()
        elseif currentMode == "File" and #mp3List > 0 then
            local nextIdx = shuffleMode and math.random(1, #mp3List) or ((currentTrackIndex % #mp3List) + 1)
            if nextIdx < 1 then nextIdx = #mp3List end
            if nextIdx > #mp3List then nextIdx = 1 end
            play(getcustomasset(mp3List[nextIdx].path), mp3List[nextIdx].name, nextIdx)
        end
    end)
end

local function updateMusicList()
    for _, v in pairs(ScrollList:GetChildren()) do 
        if v:IsA("Frame") then 
            v:Destroy() 
        end 
    end
    
    local searchText = SearchBox.Text:lower()
    filteredList = {}
    
    for _, music in ipairs(mp3List) do
        if searchText == "" or music.name:lower():match(searchText) then
            table.insert(filteredList, music)
        end
    end
    
    if #filteredList == 0 then
        local emptyFrame = Instance.new("Frame")
        emptyFrame.Size = UDim2.new(1, 0, 0, 50)
        emptyFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        emptyFrame.Parent = ScrollList
        Instance.new("UICorner", emptyFrame).CornerRadius = UDim.new(0, 10)
        
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 1, 0)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = searchText == "" and "📁 Coloque .mp3 em PHONE/Music" or "🔍 Nenhuma música encontrada"
        emptyLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
        emptyLabel.TextSize = 12
        emptyLabel.Parent = emptyFrame
    else
        for idx, music in ipairs(filteredList) do
            local btnFrame = Instance.new("Frame")
            btnFrame.Size = UDim2.new(1, 0, 0, 36)
            btnFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
            btnFrame.Parent = ScrollList
            Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 10)
            
            local t = Instance.new("TextButton")
            t.Size = UDim2.new(1, 0, 1, 0)
            t.BackgroundTransparency = 1
            t.Text = "  🎵  " .. music.name
            t.TextColor3 = Color3.new(1,1,1)
            t.TextXAlignment = Enum.TextXAlignment.Left
            t.TextSize = 13
            t.Font = Enum.Font.Gotham
            t.Parent = btnFrame
            
            t.MouseButton1Click:Connect(function()
                play(getcustomasset(music.path), music.name, idx)
            end)
            
            t.MouseEnter:Connect(function()
                btnFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
            end)
            t.MouseLeave:Connect(function()
                btnFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
            end)
        end
    end
    
    ScrollList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 8)
end

local function refreshFiles()
    mp3List = {}
    
    local paths = {"PHONE/Music/", "PHONE/Music", "PHONE\\Music"}
    local success, files = false, nil
    
    for _, p in ipairs(paths) do
        success, files = pcall(function() return listfiles(p) end)
        if success and type(files) == "table" and #files > 0 then
            break
        end
    end
    
    if success and type(files) == "table" then
        for _, file in ipairs(files) do
            if tostring(file):lower():match("%.mp3$") then
                local name = tostring(file):match("([^/\\]+)$") or tostring(file)
                name = name:gsub("%.mp3$", "")
                table.insert(mp3List, {name = name, path = file})
            end
        end
    end
    
    updateMusicList()
end

-- ========== CRONÔMETRO (direita) ==========
local StopwatchFrame = Instance.new("Frame")
StopwatchFrame.Name = "StopwatchFrame"
StopwatchFrame.Size = UDim2.new(0, 280, 0, 440)
StopwatchFrame.Position = UDim2.new(1, -300, 0.5, -220)
StopwatchFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
StopwatchFrame.BorderSizePixel = 0
StopwatchFrame.Visible = false
StopwatchFrame.Active = true
StopwatchFrame.Draggable = true
StopwatchFrame.Parent = ScreenGui

Instance.new("UICorner", StopwatchFrame).CornerRadius = UDim.new(0, 28)

local swBezel = Instance.new("UIStroke")
swBezel.Color = Color3.fromRGB(50, 205, 50)
swBezel.Thickness = 6
swBezel.Parent = StopwatchFrame

local swEars = Instance.new("ImageLabel")
swEars.Size = UDim2.new(0, 340, 0, 95)
swEars.Position = UDim2.new(0.5, -170, 0, -48)
swEars.BackgroundTransparency = 1
swEars.Image = "rbxassetid://108135642658853"
swEars.ImageColor3 = Color3.fromRGB(50, 205, 50)
swEars.ZIndex = StopwatchFrame.ZIndex + 2
swEars.Parent = StopwatchFrame

local swNotch = Instance.new("Frame")
swNotch.Size = UDim2.new(0, 82, 0, 24)
swNotch.Position = UDim2.new(0.5, -41, 0, 9)
swNotch.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
swNotch.BorderSizePixel = 0
swNotch.Parent = StopwatchFrame
Instance.new("UICorner", swNotch).CornerRadius = UDim.new(1, 0)

local swTitle = Instance.new("TextLabel")
swTitle.Size = UDim2.new(1, 0, 0, 30)
swTitle.Position = UDim2.new(0, 0, 0, 50)
swTitle.BackgroundTransparency = 1
swTitle.Text = "⏱️ Cronômetro"
swTitle.TextColor3 = Color3.new(1, 1, 1)
swTitle.Font = Enum.Font.GothamBold
swTitle.TextSize = 20
swTitle.Parent = StopwatchFrame

local swTimeLabel = Instance.new("TextLabel")
swTimeLabel.Size = UDim2.new(1, -40, 0, 80)
swTimeLabel.Position = UDim2.new(0, 20, 0, 120)
swTimeLabel.BackgroundTransparency = 1
swTimeLabel.Text = "0:00:00:00.<font size=\"18\">00</font>"
swTimeLabel.TextColor3 = Color3.fromRGB(50, 205, 50)
swTimeLabel.Font = Enum.Font.Code
swTimeLabel.TextSize = 32
swTimeLabel.RichText = true
swTimeLabel.Parent = StopwatchFrame

local swStartBtn = Instance.new("TextButton")
swStartBtn.Size = UDim2.new(0, 100, 0, 50)
swStartBtn.Position = UDim2.new(0.5, -110, 0, 230)
swStartBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
swStartBtn.Text = "▶ Iniciar"
swStartBtn.TextColor3 = Color3.new(0, 0, 0)
swStartBtn.Font = Enum.Font.GothamBold
swStartBtn.TextSize = 16
swStartBtn.Parent = StopwatchFrame
Instance.new("UICorner", swStartBtn).CornerRadius = UDim.new(0, 14)

local swResetBtn = Instance.new("TextButton")
swResetBtn.Size = UDim2.new(0, 100, 0, 50)
swResetBtn.Position = UDim2.new(0.5, 10, 0, 230)
swResetBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
swResetBtn.Text = "↺ Reset"
swResetBtn.TextColor3 = Color3.new(1, 1, 1)
swResetBtn.Font = Enum.Font.GothamBold
swResetBtn.TextSize = 16
swResetBtn.Parent = StopwatchFrame
Instance.new("UICorner", swResetBtn).CornerRadius = UDim.new(0, 14)

local swNavBtn, swBackBtn = createNavBar(StopwatchFrame)

local swRunning = false
local swStartTime = 0
local swElapsed = 0
local swConnection = nil

local function formatStopwatch(t)
    local days = math.floor(t / 86400)
    local hours = math.floor((t % 86400) / 3600)
    local mins = math.floor((t % 3600) / 60)
    local secs = math.floor(t % 60)
    local ms = math.floor((t % 1) * 100)
    return string.format("%d:%02d:%02d:%02d.<font size=\"18\">%02d</font>", days, hours, mins, secs, ms)
end

local function updateStopwatchDisplay()
    if swRunning then
        local now = os.clock()
        swTimeLabel.Text = formatStopwatch(swElapsed + (now - swStartTime))
    else
        swTimeLabel.Text = formatStopwatch(swElapsed)
    end
end

swStartBtn.MouseButton1Click:Connect(function()
    if swRunning then
        swElapsed = swElapsed + (os.clock() - swStartTime)
        swRunning = false
        swStartBtn.Text = "▶ Iniciar"
        swStartBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
        if swConnection then swConnection:Disconnect() swConnection = nil end
    else
        swStartTime = os.clock()
        swRunning = true
        swStartBtn.Text = "⏸ Pausar"
        swStartBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 30)
        if swConnection then swConnection:Disconnect() end
        swConnection = RunService.RenderStepped:Connect(updateStopwatchDisplay)
    end
end)

swResetBtn.MouseButton1Click:Connect(function()
    swRunning = false
    swElapsed = 0
    swStartTime = 0
    swTimeLabel.Text = "0:00:00:00.<font size=\"18\">00</font>"
    swStartBtn.Text = "▶ Iniciar"
    swStartBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
    if swConnection then swConnection:Disconnect() swConnection = nil end
end)

-- ========== CONFIG APP (direita) ==========
local ConfigFrame = Instance.new("Frame")
ConfigFrame.Name = "ConfigFrame"
ConfigFrame.Size = UDim2.new(0, 280, 0, 440)
ConfigFrame.Position = UDim2.new(1, -300, 0.5, -220)
ConfigFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
ConfigFrame.BorderSizePixel = 0
ConfigFrame.Visible = false
ConfigFrame.Active = true
ConfigFrame.Draggable = true
ConfigFrame.Parent = ScreenGui

Instance.new("UICorner", ConfigFrame).CornerRadius = UDim.new(0, 28)

local cfgBezel = Instance.new("UIStroke")
cfgBezel.Color = Color3.fromRGB(50, 205, 50)
cfgBezel.Thickness = 6
cfgBezel.Parent = ConfigFrame

local cfgEars = Instance.new("ImageLabel")
cfgEars.Size = UDim2.new(0, 340, 0, 95)
cfgEars.Position = UDim2.new(0.5, -170, 0, -48)
cfgEars.BackgroundTransparency = 1
cfgEars.Image = "rbxassetid://108135642658853"
cfgEars.ImageColor3 = Color3.fromRGB(50, 205, 50)
cfgEars.ZIndex = 10
cfgEars.Parent = ConfigFrame

local cfgTitle = Instance.new("TextLabel")
cfgTitle.Size = UDim2.new(1, 0, 0, 35)
cfgTitle.Position = UDim2.new(0, 0, 0, 45)
cfgTitle.BackgroundTransparency = 1
cfgTitle.Text = "⚙️ Configurações"
cfgTitle.TextColor3 = Color3.new(1,1,1)
cfgTitle.Font = Enum.Font.GothamBold
cfgTitle.TextSize = 20
cfgTitle.Parent = ConfigFrame

local cfgScroll = Instance.new("ScrollingFrame")
cfgScroll.Size = UDim2.new(1, -20, 1, -100)
cfgScroll.Position = UDim2.new(0, 10, 0, 85)
cfgScroll.BackgroundTransparency = 1
cfgScroll.ScrollBarThickness = 4
cfgScroll.Parent = ConfigFrame

local cfgLayout = Instance.new("UIListLayout")
cfgLayout.Padding = UDim.new(0, 10)
cfgLayout.Parent = cfgScroll

local function createConfigToggle(title, desc, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 70)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.Parent = cfgScroll
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local titleL = Instance.new("TextLabel")
    titleL.Size = UDim2.new(1, -70, 0, 25)
    titleL.Position = UDim2.new(0, 12, 0, 8)
    titleL.BackgroundTransparency = 1
    titleL.Text = title
    titleL.TextColor3 = Color3.new(1,1,1)
    titleL.Font = Enum.Font.GothamBold
    titleL.TextSize = 14
    titleL.TextXAlignment = Enum.TextXAlignment.Left
    titleL.Parent = frame

    local descL = Instance.new("TextLabel")
    descL.Size = UDim2.new(1, -70, 0, 30)
    descL.Position = UDim2.new(0, 12, 0, 32)
    descL.BackgroundTransparency = 1
    descL.Text = desc
    descL.TextColor3 = Color3.fromRGB(160, 160, 170)
    descL.Font = Enum.Font.Gotham
    descL.TextSize = 11
    descL.TextXAlignment = Enum.TextXAlignment.Left
    descL.TextWrapped = true
    descL.Parent = frame

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 50, 0, 28)
    toggle.Position = UDim2.new(1, -60, 0.5, -14)
    toggle.BackgroundColor3 = default and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(60, 60, 65)
    toggle.Text = default and "ON" or "OFF"
    toggle.TextColor3 = Color3.new(1,1,1)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 12
    toggle.Parent = frame
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 14)

    local state = default
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(60, 60, 65)
        toggle.Text = state and "ON" or "OFF"
        callback(state)
    end)

    return frame
end

createConfigToggle("FPS Counter", "Mostra o FPS na tela inicial do celular", false, function(on)
    phoneSettings.fpsEnabled = on
    if fpsLabel then
        fpsLabel.Visible = on
    end
end)

createConfigToggle("Lanterna do Celular", "Liga uma luz fraca na frente do personagem", false, function(on)
    phoneSettings.flashlightEnabled = on
    if on then
        if phoneFlashlight then phoneFlashlight:Destroy() end
        local root = Character and Character:FindFirstChild("HumanoidRootPart")
        if root then
            phoneFlashlight = Instance.new("SpotLight")
            phoneFlashlight.Name = "PhoneFlashlight"
            phoneFlashlight.Brightness = 2.5
            phoneFlashlight.Range = 35
            phoneFlashlight.Angle = 50
            phoneFlashlight.Face = Enum.NormalId.Front
            phoneFlashlight.Parent = root
        end
    else
        if phoneFlashlight then
            phoneFlashlight:Destroy()
            phoneFlashlight = nil
        end
    end
end)

local serverInfoFrame = Instance.new("Frame")
serverInfoFrame.Size = UDim2.new(1, 0, 0, 110)
serverInfoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
serverInfoFrame.Parent = cfgScroll
Instance.new("UICorner", serverInfoFrame).CornerRadius = UDim.new(0, 12)

local serverTitle = Instance.new("TextLabel")
serverTitle.Size = UDim2.new(1, -20, 0, 25)
serverTitle.Position = UDim2.new(0, 12, 0, 8)
serverTitle.BackgroundTransparency = 1
serverTitle.Text = "📡 Info do Servidor"
serverTitle.TextColor3 = Color3.new(1,1,1)
serverTitle.Font = Enum.Font.GothamBold
serverTitle.TextSize = 14
serverTitle.TextXAlignment = Enum.TextXAlignment.Left
serverTitle.Parent = serverInfoFrame

local serverInfoLabel = Instance.new("TextLabel")
serverInfoLabel.Size = UDim2.new(1, -24, 0, 70)
serverInfoLabel.Position = UDim2.new(0, 12, 0, 35)
serverInfoLabel.BackgroundTransparency = 1
serverInfoLabel.Text = "Carregando..."
serverInfoLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
serverInfoLabel.Font = Enum.Font.Code
serverInfoLabel.TextSize = 13
serverInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
serverInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
serverInfoLabel.TextWrapped = true
serverInfoLabel.Parent = serverInfoFrame

task.spawn(function()
    while true do
        local playersCount = #Players:GetPlayers()
        local maxPlayers = Players.MaxPlayers
        local onlineTime = os.clock() - phoneSettings.joinTime
        local mins = math.floor(onlineTime / 60)
        local secs = math.floor(onlineTime % 60)
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)

        local serverType = (game.JobId ~= "" and game.PrivateServerId ~= "") and "Privado" or "Público"

        serverInfoLabel.Text = string.format(
            "Players: %d / %d\nTempo Online: %02d:%02d\nPing: %d ms\nServer: %s",
            playersCount, maxPlayers, mins, secs, ping, serverType
        )
        task.wait(2)
    end
end)

cfgScroll.CanvasSize = UDim2.new(0, 0, 0, cfgLayout.AbsoluteContentSize.Y + 20)
cfgLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    cfgScroll.CanvasSize = UDim2.new(0, 0, 0, cfgLayout.AbsoluteContentSize.Y + 20)
end)

local cfgNavBtn, cfgBackBtn = createNavBar(ConfigFrame)

-- ========== GALERIA APP (direita) ==========
local GalleryFrame = Instance.new("Frame")
GalleryFrame.Name = "GalleryFrame"
GalleryFrame.Size = UDim2.new(0, 280, 0, 440)
GalleryFrame.Position = UDim2.new(1, -300, 0.5, -220)
GalleryFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
GalleryFrame.BorderSizePixel = 0
GalleryFrame.Visible = false
GalleryFrame.Active = true
GalleryFrame.Draggable = true
GalleryFrame.Parent = ScreenGui

Instance.new("UICorner", GalleryFrame).CornerRadius = UDim.new(0, 28)

local galBezel = Instance.new("UIStroke")
galBezel.Color = Color3.fromRGB(50, 205, 50)
galBezel.Thickness = 6
galBezel.Parent = GalleryFrame

local galEars = Instance.new("ImageLabel")
galEars.Size = UDim2.new(0, 340, 0, 95)
galEars.Position = UDim2.new(0.5, -170, 0, -48)
galEars.BackgroundTransparency = 1
galEars.Image = "rbxassetid://108135642658853"
galEars.ImageColor3 = Color3.fromRGB(50, 205, 50)
galEars.ZIndex = GalleryFrame.ZIndex + 2
galEars.Parent = GalleryFrame

local galNotch = Instance.new("Frame")
galNotch.Size = UDim2.new(0, 82, 0, 24)
galNotch.Position = UDim2.new(0.5, -41, 0, 9)
galNotch.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
galNotch.BorderSizePixel = 0
galNotch.Parent = GalleryFrame
Instance.new("UICorner", galNotch).CornerRadius = UDim.new(1, 0)

local galTitle = Instance.new("TextLabel")
galTitle.Size = UDim2.new(1, 0, 0, 30)
galTitle.Position = UDim2.new(0, 0, 0, 42)
galTitle.BackgroundTransparency = 1
galTitle.Text = "🖼️ Galeria"
galTitle.TextColor3 = Color3.new(1, 1, 1)
galTitle.Font = Enum.Font.GothamBold
galTitle.TextSize = 20
galTitle.Parent = GalleryFrame

local PhotoSearchBox = Instance.new("TextBox")
PhotoSearchBox.Size = UDim2.new(1, -24, 0, 32)
PhotoSearchBox.Position = UDim2.new(0, 12, 0, 80)
PhotoSearchBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
PhotoSearchBox.PlaceholderText = "🔍 Pesquisar foto..."
PhotoSearchBox.Text = ""
PhotoSearchBox.TextColor3 = Color3.new(1, 1, 1)
PhotoSearchBox.Font = Enum.Font.Gotham
PhotoSearchBox.TextSize = 13
PhotoSearchBox.Parent = GalleryFrame
Instance.new("UICorner", PhotoSearchBox).CornerRadius = UDim.new(0, 10)
local photoSearchStroke = Instance.new("UIStroke")
photoSearchStroke.Color = Color3.fromRGB(50, 205, 50)
photoSearchStroke.Thickness = 1.2
photoSearchStroke.Parent = PhotoSearchBox

local PhotoScrollList = Instance.new("ScrollingFrame")
PhotoScrollList.Size = UDim2.new(1, -24, 0, 280)
PhotoScrollList.Position = UDim2.new(0, 12, 0, 120)
PhotoScrollList.BackgroundTransparency = 1
PhotoScrollList.ScrollBarThickness = 3
PhotoScrollList.ScrollBarImageColor3 = Color3.fromRGB(50, 205, 50)
PhotoScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
PhotoScrollList.Parent = GalleryFrame

local PhotoUIGridLayout = Instance.new("UIGridLayout")
PhotoUIGridLayout.CellSize = UDim2.new(0, 58, 0, 58)
PhotoUIGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
PhotoUIGridLayout.FillDirection = Enum.FillDirection.Horizontal
PhotoUIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
PhotoUIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
PhotoUIGridLayout.Parent = PhotoScrollList

-- Viewer de foto (zoom)
local PhotoViewerView = Instance.new("Frame")
PhotoViewerView.Name = "PhotoViewerView"
PhotoViewerView.Size = UDim2.new(1, 0, 1, 0)
PhotoViewerView.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PhotoViewerView.BorderSizePixel = 0
PhotoViewerView.Visible = false
PhotoViewerView.Parent = GalleryFrame
Instance.new("UICorner", PhotoViewerView).CornerRadius = UDim.new(0, 28)

local PhotoDisplay = Instance.new("ImageLabel")
PhotoDisplay.Name = "PhotoDisplay"
PhotoDisplay.Size = UDim2.new(1, -16, 1, -110)
PhotoDisplay.Position = UDim2.new(0, 8, 0, 40)
PhotoDisplay.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
PhotoDisplay.BackgroundTransparency = 0.3
PhotoDisplay.BorderSizePixel = 0
PhotoDisplay.ScaleType = Enum.ScaleType.Fit
PhotoDisplay.Parent = PhotoViewerView
Instance.new("UICorner", PhotoDisplay).CornerRadius = UDim.new(0, 12)

local PhotoNameLabel = Instance.new("TextLabel")
PhotoNameLabel.Size = UDim2.new(1, -20, 0, 24)
PhotoNameLabel.Position = UDim2.new(0, 10, 1, -95)
PhotoNameLabel.BackgroundTransparency = 1
PhotoNameLabel.Text = ""
PhotoNameLabel.TextColor3 = Color3.new(1, 1, 1)
PhotoNameLabel.Font = Enum.Font.GothamBold
PhotoNameLabel.TextSize = 14
PhotoNameLabel.TextXAlignment = Enum.TextXAlignment.Center
PhotoNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
PhotoNameLabel.Parent = PhotoViewerView

-- Botões de navegação da galeria (anterior / próxima)
local prevPhotoBtn = Instance.new("TextButton")
prevPhotoBtn.Name = "PrevPhoto"
prevPhotoBtn.Size = UDim2.new(0, 70, 0, 36)
prevPhotoBtn.Position = UDim2.new(0, 20, 1, -55)
prevPhotoBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
prevPhotoBtn.Text = "◀ Anterior"
prevPhotoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prevPhotoBtn.Font = Enum.Font.GothamBold
prevPhotoBtn.TextSize = 13
prevPhotoBtn.Parent = PhotoViewerView
Instance.new("UICorner", prevPhotoBtn).CornerRadius = UDim.new(0, 10)

local nextPhotoBtn = Instance.new("TextButton")
nextPhotoBtn.Name = "NextPhoto"
nextPhotoBtn.Size = UDim2.new(0, 70, 0, 36)
nextPhotoBtn.Position = UDim2.new(1, -90, 1, -55)
nextPhotoBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
nextPhotoBtn.Text = "Próxima ▶"
nextPhotoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
nextPhotoBtn.Font = Enum.Font.GothamBold
nextPhotoBtn.TextSize = 13
nextPhotoBtn.Parent = PhotoViewerView
Instance.new("UICorner", nextPhotoBtn).CornerRadius = UDim.new(0, 10)

local galNavBtn, galBackBtn = createNavBar(GalleryFrame)

local function exitPhotoViewer()
    isInPhotoViewer = false
    PhotoViewerView.Visible = false
    PhotoScrollList.Visible = true
    PhotoSearchBox.Visible = true
    galTitle.Visible = true
    PhotoDisplay.Image = ""
    PhotoNameLabel.Text = ""
    currentPhotoIndex = 0
end

local function openPhotoByIndex(idx)
    if #filteredPhotoList == 0 then return end
    if idx < 1 then idx = #filteredPhotoList end
    if idx > #filteredPhotoList then idx = 1 end
    currentPhotoIndex = idx

    local photo = filteredPhotoList[idx]
    isInPhotoViewer = true
    PhotoViewerView.Visible = true
    PhotoScrollList.Visible = false
    PhotoSearchBox.Visible = false
    galTitle.Visible = false

    PhotoNameLabel.Text = (photo.name or "Foto") .. "  (" .. idx .. "/" .. #filteredPhotoList .. ")"

    local success, asset = pcall(function()
        return getcustomasset(photo.path)
    end)

    if success and asset then
        PhotoDisplay.Image = asset
        PhotoDisplay.ScaleType = Enum.ScaleType.Fit
    else
        PhotoNameLabel.Text = "Erro ao carregar foto"
        PhotoDisplay.Image = ""
    end
end

local function openPhoto(path, name)
    -- encontra o índice da foto na lista filtrada
    local foundIdx = 1
    for i, p in ipairs(filteredPhotoList) do
        if p.path == path then
            foundIdx = i
            break
        end
    end
    openPhotoByIndex(foundIdx)
end

prevPhotoBtn.MouseButton1Click:Connect(function()
    if #filteredPhotoList > 0 then
        openPhotoByIndex(currentPhotoIndex - 1)
    end
end)

nextPhotoBtn.MouseButton1Click:Connect(function()
    if #filteredPhotoList > 0 then
        openPhotoByIndex(currentPhotoIndex + 1)
    end
end)

local function updatePhotoList()
    for _, v in pairs(PhotoScrollList:GetChildren()) do
        if v:IsA("Frame") or v:IsA("ImageButton") then v:Destroy() end
    end

    local searchText = PhotoSearchBox.Text:lower()
    filteredPhotoList = {}

    for _, photo in ipairs(photoList) do
        if searchText == "" or photo.name:lower():match(searchText) then
            table.insert(filteredPhotoList, photo)
        end
    end

    if #filteredPhotoList == 0 then
        local emptyFrame = Instance.new("Frame")
        emptyFrame.Size = UDim2.new(1, 0, 0, 50)
        emptyFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        emptyFrame.Parent = PhotoScrollList
        Instance.new("UICorner", emptyFrame).CornerRadius = UDim.new(0, 10)

        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 1, 0)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = searchText == "" and "📁 Coloque fotos em PHONE/Photos" or "🔍 Nenhuma foto encontrada"
        emptyLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
        emptyLabel.TextSize = 12
        emptyLabel.Parent = emptyFrame
    else
        for idx, photo in ipairs(filteredPhotoList) do
            local thumbBtn = Instance.new("ImageButton")
            thumbBtn.Size = UDim2.new(0, 58, 0, 58)
            thumbBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            thumbBtn.BorderSizePixel = 0
            thumbBtn.ScaleType = Enum.ScaleType.Crop
            thumbBtn.AutoButtonColor = false
            thumbBtn.Parent = PhotoScrollList
            Instance.new("UICorner", thumbBtn).CornerRadius = UDim.new(0, 10)

            pcall(function()
                local asset = getcustomasset(photo.path)
                if asset then
                    thumbBtn.Image = asset
                end
            end)

            thumbBtn.MouseButton1Click:Connect(function()
                openPhoto(photo.path, photo.name)
            end)

            thumbBtn.MouseEnter:Connect(function()
                TweenService:Create(thumbBtn, TweenInfo.new(0.12), {
                    BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                }):Play()
            end)
            thumbBtn.MouseLeave:Connect(function()
                TweenService:Create(thumbBtn, TweenInfo.new(0.12), {
                    BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                }):Play()
            end)
        end
    end

    task.wait()
    PhotoScrollList.CanvasSize = UDim2.new(0, 0, 0, PhotoUIGridLayout.AbsoluteContentSize.Y + 10)
end

local function refreshPhotos()
    photoList = {}
    local paths = {
        "PHONE/Photos/",
        "PHONE/Photos",
        "PHONE\\Photos",
        "Photos/",
        "Photos"
    }
    local files = nil
    local success = false

    for _, p in ipairs(paths) do
        success, files = pcall(function() return listfiles(p) end)
        if success and type(files) == "table" and #files > 0 then
            break
        end
    end

    if success and type(files) == "table" then
        for _, file in ipairs(files) do
            local str = tostring(file)
            local lower = str:lower()
            if lower:match("%.png$") or lower:match("%.jpg$") or lower:match("%.jpeg$") or lower:match("%.webp$") or lower:match("%.bmp$") or lower:match("%.gif$") then
                local name = str:match("([^/\\]+)$") or str
                name = name:gsub("%.%w+$", "")
                table.insert(photoList, {name = name, path = file})
            end
        end
    end
    updatePhotoList()
end

PhotoSearchBox.Changed:Connect(function(prop)
    if prop == "Text" then
        updatePhotoList()
    end
end)

-- ========== NAVEGAÇÃO ==========
local function openHomeScreen()
    isInPhotoViewer = false
    exitPhotoViewer()

    currentApp = "home"
    local currentPos = PhoneHome.Position
    if MainFrame.Visible then currentPos = MainFrame.Position end
    if StopwatchFrame.Visible then currentPos = StopwatchFrame.Position end
    if ConfigFrame.Visible then currentPos = ConfigFrame.Position end
    if GalleryFrame.Visible then currentPos = GalleryFrame.Position end

    PhoneHome.Position = currentPos
    MainFrame.Position = currentPos
    StopwatchFrame.Position = currentPos
    ConfigFrame.Position = currentPos
    GalleryFrame.Position = currentPos

    PhoneHome.Visible = true
    MainFrame.Visible = false
    StopwatchFrame.Visible = false
    ConfigFrame.Visible = false
    GalleryFrame.Visible = false
    isMusicOpen = false

    attachVolumeTo(PhoneHome)
end

local function openMusicApp()
    isInPhotoViewer = false
    exitPhotoViewer()

    currentApp = "music"
    local currentPos = PhoneHome.Position
    if MainFrame.Visible then currentPos = MainFrame.Position end
    if StopwatchFrame.Visible then currentPos = StopwatchFrame.Position end
    if ConfigFrame.Visible then currentPos = ConfigFrame.Position end
    if GalleryFrame.Visible then currentPos = GalleryFrame.Position end

    PhoneHome.Position = currentPos
    MainFrame.Position = currentPos
    StopwatchFrame.Position = currentPos
    ConfigFrame.Position = currentPos
    GalleryFrame.Position = currentPos

    PhoneHome.Visible = false
    MainFrame.Visible = true
    StopwatchFrame.Visible = false
    ConfigFrame.Visible = false
    GalleryFrame.Visible = false
    isMusicOpen = true

    refreshFiles()
    attachVolumeTo(MainFrame)
end

local function openStopwatchApp()
    isInPhotoViewer = false
    exitPhotoViewer()

    currentApp = "stopwatch"
    local currentPos = PhoneHome.Position
    if MainFrame.Visible then currentPos = MainFrame.Position end
    if StopwatchFrame.Visible then currentPos = StopwatchFrame.Position end
    if ConfigFrame.Visible then currentPos = ConfigFrame.Position end
    if GalleryFrame.Visible then currentPos = GalleryFrame.Position end

    PhoneHome.Position = currentPos
    MainFrame.Position = currentPos
    StopwatchFrame.Position = currentPos
    ConfigFrame.Position = currentPos
    GalleryFrame.Position = currentPos

    PhoneHome.Visible = false
    MainFrame.Visible = false
    StopwatchFrame.Visible = true
    ConfigFrame.Visible = false
    GalleryFrame.Visible = false
    isMusicOpen = false

    attachVolumeTo(StopwatchFrame)
end

local function openConfigApp()
    isInPhotoViewer = false
    exitPhotoViewer()

    currentApp = "config"
    local currentPos = PhoneHome.Position
    if MainFrame.Visible then currentPos = MainFrame.Position end
    if StopwatchFrame.Visible then currentPos = StopwatchFrame.Position end
    if ConfigFrame.Visible then currentPos = ConfigFrame.Position end
    if GalleryFrame.Visible then currentPos = GalleryFrame.Position end

    PhoneHome.Position = currentPos
    MainFrame.Position = currentPos
    StopwatchFrame.Position = currentPos
    ConfigFrame.Position = currentPos
    GalleryFrame.Position = currentPos

    PhoneHome.Visible = false
    MainFrame.Visible = false
    StopwatchFrame.Visible = false
    ConfigFrame.Visible = true
    GalleryFrame.Visible = false
    isMusicOpen = false

    attachVolumeTo(ConfigFrame)
end

local function openGalleryApp()
    isInPhotoViewer = false
    exitPhotoViewer()

    currentApp = "gallery"
    local currentPos = PhoneHome.Position
    if MainFrame.Visible then currentPos = MainFrame.Position end
    if StopwatchFrame.Visible then currentPos = StopwatchFrame.Position end
    if ConfigFrame.Visible then currentPos = ConfigFrame.Position end
    if GalleryFrame.Visible then currentPos = GalleryFrame.Position end

    PhoneHome.Position = currentPos
    MainFrame.Position = currentPos
    StopwatchFrame.Position = currentPos
    ConfigFrame.Position = currentPos
    GalleryFrame.Position = currentPos

    PhoneHome.Visible = false
    MainFrame.Visible = false
    StopwatchFrame.Visible = false
    ConfigFrame.Visible = false
    GalleryFrame.Visible = true
    isMusicOpen = false

    refreshPhotos()
    attachVolumeTo(GalleryFrame)
end

local function goHome()
    if currentApp == "home" then return end
    openHomeScreen()
end

local function handleBack()
    if currentApp == "gallery" and isInPhotoViewer then
        exitPhotoViewer()
    end
end

homeNavBtn.MouseButton1Click:Connect(goHome)
musicNavBtn.MouseButton1Click:Connect(goHome)
swNavBtn.MouseButton1Click:Connect(goHome)
cfgNavBtn.MouseButton1Click:Connect(goHome)
galNavBtn.MouseButton1Click:Connect(goHome)

homeBackBtn.MouseButton1Click:Connect(handleBack)
musicBackBtn.MouseButton1Click:Connect(handleBack)
swBackBtn.MouseButton1Click:Connect(handleBack)
cfgBackBtn.MouseButton1Click:Connect(handleBack)
galBackBtn.MouseButton1Click:Connect(handleBack)

MusicAppIcon.MouseButton1Click:Connect(openMusicApp)
StopwatchAppIcon.MouseButton1Click:Connect(openStopwatchApp)
ConfigAppIcon.MouseButton1Click:Connect(openConfigApp)
GalleryAppIcon.MouseButton1Click:Connect(openGalleryApp)

closePhone = function()
    isInPhotoViewer = false
    exitPhotoViewer()

    local target = UDim2.new(1, -300, 1, 80)
    local frames = {PhoneHome, MainFrame, StopwatchFrame, ConfigFrame, GalleryFrame}
    for _, f in ipairs(frames) do
        if f.Visible then
            local tween = TweenService:Create(f, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = target})
            tween:Play()
            tween.Completed:Once(function()
                f.Visible = false
            end)
        end
    end
    VolumeFrame.Visible = false
    isPhoneOpen = false
    isMusicOpen = false
    currentApp = "home"
    updateMovementStats()

    -- Se o phone estava equipado via hotbar, desequipa
    if equippedItem == "TzesPhone" then
        equippedItem = nil
    end
end

openPhone = function()
    isPhoneOpen = true
    openHomeScreen()
    PhoneHome.Position = UDim2.new(1, -300, 1, 80)
    PhoneHome.Visible = true
    local target = UDim2.new(1, -300, 0.5, -220)
    local tween = TweenService:Create(PhoneHome, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = target})
    tween:Play()
    attachVolumeTo(PhoneHome)
    updateMovementStats()
end

togglePhone = function()
    if isPhoneOpen then
        closePhone()
    else
        openPhone()
    end
end

SearchBox.Changed:Connect(function(prop)
    if prop == "Text" then
        updateMusicList()
    end
end)

ModeBtn.MouseButton1Click:Connect(function()
    if currentMode == "File" then
        currentMode = "ID"
        ModeBtn.Text = "Sound ID"
        ModeBtn.TextColor3 = Color3.fromRGB(50, 205, 50)
        ScrollList.Visible = false
        SearchBox.Visible = false
        IDInput.Visible = true
    else
        currentMode = "File"
        ModeBtn.Text = "Arquivo"
        ModeBtn.TextColor3 = Color3.fromRGB(50, 205, 50)
        ScrollList.Visible = true
        SearchBox.Visible = true
        IDInput.Visible = false
        refreshFiles()
    end
end)

IDInput.FocusLost:Connect(function(enter)
    if enter and IDInput.Text ~= "" then
        local id = "rbxassetid://" .. IDInput.Text:gsub("%D", "")
        play(id, "ID: " .. IDInput.Text, 0)
    end
end)

PlayBtn.MouseButton1Click:Connect(function()
    if not currentSound then return end
    if isPaused then
        currentSound:Resume()
        PlayBtn.Text = "⏸"
    else
        currentSound:Pause()
        PlayBtn.Text = "▶"
    end
    isPaused = not isPaused
end)

NextBtn.MouseButton1Click:Connect(function()
    if currentMode == "File" and #mp3List > 0 then
        local nextIdx = shuffleMode and math.random(1, #mp3List) or ((currentTrackIndex % #mp3List) + 1)
        if nextIdx < 1 then nextIdx = #mp3List end
        if nextIdx > #mp3List then nextIdx = 1 end
        play(getcustomasset(mp3List[nextIdx].path), mp3List[nextIdx].name, nextIdx)
    end
end)

PrevBtn.MouseButton1Click:Connect(function()
    if currentMode == "File" and #mp3List > 0 then
        local prevIdx = shuffleMode and math.random(1, #mp3List) or (currentTrackIndex - 1)
        if prevIdx < 1 then prevIdx = #mp3List end
        play(getcustomasset(mp3List[prevIdx].path), mp3List[prevIdx].name, prevIdx)
    end
end)

ShuffleBtn.MouseButton1Click:Connect(function()
    shuffleMode = not shuffleMode
    ShuffleBtn.Text = shuffleMode and "🔀" or "➡️"
    ShuffleBtn.BackgroundColor3 = shuffleMode and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(28, 28, 34)
end)

RepeatBtn.MouseButton1Click:Connect(function()
    repeatMode = not repeatMode
    RepeatBtn.Text = repeatMode and "🔁" or "🔂"
    RepeatBtn.BackgroundColor3 = repeatMode and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(28, 28, 34)
end)

RunService.RenderStepped:Connect(function()
    if currentSound and (currentSound.IsPlaying or isPaused) then
        local duration = currentSound.TimeLength
        local current = currentSound.TimePosition
        if duration > 0 then
            local progress = current / duration
            TimeBarFill.Size = UDim2.new(progress, 0, 1, 0)
            TimeLabel.Text = formatTime(current) .. " / " .. formatTime(duration)
        end
    end
end)

refreshFiles()
refreshPhotos()
end -- fim do if selectedItems.TzesPhone

-- =========================================================
-- CHARACTER HANDLING (sem criação de Tools)
-- =========================================================
local function onCharacterAdded(char)
    cleanup()
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    
    originalWalkSpeed = Humanoid.WalkSpeed
    phoneSettings.joinTime = os.clock()

    local cam = Workspace.CurrentCamera
    if cam then
        originalFOV = cam.FieldOfView
    end

    removeExtraRoots()
    createSounds()

    Humanoid.JumpPower = SETTINGS.JumpPower
end

Player.CharacterRemoving:Connect(cleanup)
Player.CharacterAdded:Connect(onCharacterAdded)
if Player.Character then onCharacterAdded(Player.Character) end
