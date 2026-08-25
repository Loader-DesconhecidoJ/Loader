-- =========================================================
-- MENU DE SELEÇÃO INICIAL (apenas Phone)
-- =========================================================
local selectedItems = {
    TzesPhone   = true
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
    Main.Size = UDim2.new(0, 210, 0, 110)
    Main.Position = UDim2.new(0.5, -105, 0.5, -55)
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
    title.Text = "Itens selecionados"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.Parent = Main

    local phoneBtn = Instance.new("TextButton")
    phoneBtn.Name = "TzesPhone"
    phoneBtn.Size = UDim2.new(0, 190, 0, 28)
    phoneBtn.Position = UDim2.new(0, 10, 0, 32)
    phoneBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
    phoneBtn.Text = "📱 Phone"
    phoneBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
    phoneBtn.Font = Enum.Font.GothamBold
    phoneBtn.TextSize = 12
    phoneBtn.AutoButtonColor = false
    phoneBtn.Parent = Main
    Instance.new("UICorner", phoneBtn).CornerRadius = UDim.new(0, 8)

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(40, 160, 40)
    btnStroke.Thickness = 1.2
    btnStroke.Parent = phoneBtn

    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Size = UDim2.new(0, 190, 0, 26)
    confirmBtn.Position = UDim2.new(0, 10, 0, 70)
    confirmBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
    confirmBtn.Text = "Confirmar"
    confirmBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.TextSize = 12
    confirmBtn.AutoButtonColor = false
    confirmBtn.Parent = Main
    Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 7)

    confirmBtn.MouseButton1Click:Connect(function()
        selectedItems.TzesPhone = true
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
-- SISTEMA DE CONFIG PERSISTENTE (JSON)
-- =========================================================
local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "PHONE/config.json"

local defaultConfig = {
    wallpaper = "rbxassetid://12506271392", -- padrão
    wallpaperType = "asset", -- "asset" ou "custom"
    fpsEnabled = false,
    flashlightEnabled = false
}

local function loadConfig()
    local cfg = defaultConfig
    pcall(function()
        if isfile(CONFIG_FILE) then
            local content = readfile(CONFIG_FILE)
            local decoded = HttpService:JSONDecode(content)
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    cfg[k] = v
                end
            end
        else
            writefile(CONFIG_FILE, HttpService:JSONEncode(defaultConfig))
        end
    end)
    return cfg
end

local function saveConfig(cfg)
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(cfg))
    end)
end

local savedConfig = loadConfig()

-- =========================================================
-- SCRIPT PRINCIPAL (só cria o que foi selecionado)
-- =========================================================
local SETTINGS = {
    JumpPower        = 50,
    Enabled          = true
}

local Player = game.Players.LocalPlayer
local Character, Humanoid
local originalWalkSpeed = 16

local isPhoneOpen = false
local isMusicOpen = false
local fovTween = nil

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")

local isTouchDevice = UserInputService.TouchEnabled

local SOUNDS = {}

local phoneSettings = {
    fpsEnabled = savedConfig.fpsEnabled or false,
    flashlightEnabled = savedConfig.flashlightEnabled or false,
    joinTime = os.clock()
}

local fpsLabel = nil
local phoneFlashlight = nil

-- Estados de "equipamento" via hotbar (sem Tools)
local equippedItem = nil          -- "TzesPhone" | nil

local function createSounds()
    for _, sound in pairs(Player:WaitForChild("PlayerGui"):GetChildren()) do
        if sound:IsA("Sound") and (sound.SoundId == "rbxassetid://138475744729338") then
            sound:Destroy()
        end
    end
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
end

local function cleanup()
    resetFOV()

    if Humanoid then
        Humanoid.JumpPower = SETTINGS.JumpPower
        Humanoid.WalkSpeed = originalWalkSpeed
    end

    if phoneFlashlight then
        phoneFlashlight:Destroy()
        phoneFlashlight = nil
    end

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
    Humanoid.WalkSpeed = originalWalkSpeed
    Humanoid.JumpPower = SETTINGS.JumpPower
end

-- =========================================================
-- CUSTOM HOTBAR (só Phone) - SEM TOOLS + SISTEMA DE ARRASTAR
-- =========================================================
local HotbarGui = Instance.new("ScreenGui")
HotbarGui.Name = "TzeCustomHotbar"
HotbarGui.ResetOnSpawn = false
HotbarGui.IgnoreGuiInset = true
HotbarGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HotbarGui.Parent = game:GetService("CoreGui")

local HotbarFrame = Instance.new("Frame")
HotbarFrame.Name = "HotbarFrame"
HotbarFrame.Size = UDim2.new(0, 42, 0, 40)
HotbarFrame.Position = UDim2.new(1, -52, 1, -72)
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
    {Name = "TzesPhone",  Emoji = "📱", Color = Color3.fromRGB(50, 205, 50),   ToolName = "TzesPhone"}
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
    -- Phone (fecha se estiver aberto)
    if isPhoneOpen and closePhone then
        closePhone()
    end

    equippedItem = nil
end

local function equipItem(toolName)
    if equippedItem == toolName then
        unequipAll()
        return
    end

    unequipAll()
    equippedItem = toolName

    if toolName == "TzesPhone" then
        if togglePhone then
            togglePhone()
        end
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

    -- Sistema de arrastar: segurar 0.45s
    local holdStart = 0
    local isHolding = false
    local isDragging = false
    local dragStartPos = nil
    local frameStartPos = nil
    local holdConnection = nil
    local dragConnection = nil

    local function stopDrag()
        isDragging = false
        isHolding = false
        if holdConnection then
            holdConnection:Disconnect()
            holdConnection = nil
        end
        if dragConnection then
            dragConnection:Disconnect()
            dragConnection = nil
        end
        -- Animação de soltar
        TweenService:Create(slot, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 32, 0, 32),
            BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        }):Play()
        TweenService:Create(HotbarFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        }):Play()
    end

    slot.MouseButton1Down:Connect(function()
        isHolding = true
        holdStart = os.clock()
        dragStartPos = UserInputService:GetMouseLocation()
        frameStartPos = HotbarFrame.Position

        if holdConnection then holdConnection:Disconnect() end
        holdConnection = RunService.Heartbeat:Connect(function()
            if not isHolding then return end
            local elapsed = os.clock() - holdStart
            if elapsed >= 0.45 and not isDragging then
                isDragging = true
                -- Animação de entrar em modo arrastar
                TweenService:Create(slot, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 38, 0, 38),
                    BackgroundColor3 = Color3.fromRGB(50, 205, 50)
                }):Play()
                TweenService:Create(HotbarFrame, TweenInfo.new(0.2), {
                    BackgroundTransparency = 0.7
                }):Play()

                if dragConnection then dragConnection:Disconnect() end
                dragConnection = RunService.RenderStepped:Connect(function()
                    if not isDragging then return end
                    local mouse = UserInputService:GetMouseLocation()
                    local delta = mouse - dragStartPos
                    local cam = Workspace.CurrentCamera
                    if cam then
                        local scale = hotbarUIScale.Scale
                        HotbarFrame.Position = UDim2.new(
                            frameStartPos.X.Scale,
                            frameStartPos.X.Offset + (delta.X / scale),
                            frameStartPos.Y.Scale,
                            frameStartPos.Y.Offset + (delta.Y / scale)
                        )
                    end
                end)
            end
        end)
    end)

    slot.MouseButton1Up:Connect(function()
        local wasDragging = isDragging
        stopDrag()
        if not wasDragging then
            -- Clique normal = equip
            equipItem(data.ToolName)
        end
    end)

    slot.MouseLeave:Connect(function()
        if isHolding and not isDragging then
            stopDrag()
        end
    end)

    -- Touch support
    slot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            isHolding = true
            holdStart = os.clock()
            dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
            frameStartPos = HotbarFrame.Position

            if holdConnection then holdConnection:Disconnect() end
            holdConnection = RunService.Heartbeat:Connect(function()
                if not isHolding then return end
                local elapsed = os.clock() - holdStart
                if elapsed >= 0.45 and not isDragging then
                    isDragging = true
                    TweenService:Create(slot, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 38, 0, 38),
                        BackgroundColor3 = Color3.fromRGB(50, 205, 50)
                    }):Play()
                end
            end)
        end
    end)

    slot.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPos
            local scale = hotbarUIScale.Scale
            HotbarFrame.Position = UDim2.new(
                frameStartPos.X.Scale,
                frameStartPos.X.Offset + (delta.X / scale),
                frameStartPos.Y.Scale,
                frameStartPos.Y.Offset + (delta.Y / scale)
            )
        end
    end)

    slot.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local wasDragging = isDragging
            stopDrag()
            if not wasDragging then
                equipItem(data.ToolName)
            end
        end
    end)

    slot.MouseEnter:Connect(function()
        if not isDragging then
            TweenService:Create(slot, TweenInfo.new(0.12), {
                BackgroundColor3 = Color3.fromRGB(42, 42, 52),
                Size = UDim2.new(0, 34, 0, 34)
            }):Play()
        end
    end)

    slot.MouseLeave:Connect(function()
        if not isDragging then
            TweenService:Create(slot, TweenInfo.new(0.12), {
                BackgroundColor3 = Color3.fromRGB(28, 28, 36),
                Size = UDim2.new(0, 32, 0, 32)
            }):Play()
        end
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
-- TZE PHONE SYSTEM + MUSIC + CRONÔMETRO + CONFIG + GALERIA + CÂMERA
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

local function createNavBar(parent)
    local navBar = Instance.new("Frame")
    navBar.Name = "NavBar"
    navBar.Size = UDim2.new(1, 0, 0, 48)
    navBar.Position = UDim2.new(0, 0, 1, -48)
    navBar.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    navBar.BackgroundTransparency = 0.15
    navBar.BorderSizePixel = 0
    navBar.ZIndex = 20
    navBar.Parent = parent
    Instance.new("UICorner", navBar).CornerRadius = UDim.new(0, 0)

    -- ◀  fica na ESQUERDA
    local backBtn = Instance.new("TextButton")
    backBtn.Name = "BackBtn"
    backBtn.Size = UDim2.new(0, 50, 0, 36)
    backBtn.Position = UDim2.new(0, 8, 0.5, -18)
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
homeBg.Image = savedConfig.wallpaper or "rbxassetid://12506271392"
homeBg.ScaleType = Enum.ScaleType.Crop
homeBg.ZIndex = 1
homeBg.Parent = PhoneHome
Instance.new("UICorner", homeBg).CornerRadius = UDim.new(0, 28)

-- Se for custom path, tenta carregar
if savedConfig.wallpaperType == "custom" and savedConfig.wallpaper and savedConfig.wallpaper ~= "" then
    pcall(function()
        local asset = getcustomasset(savedConfig.wallpaper)
        if asset then
            homeBg.Image = asset
        end
    end)
end

local homeOverlay = Instance.new("Frame")
homeOverlay.Size = UDim2.new(1, 0, 1, 0)
homeOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
homeOverlay.BackgroundTransparency = 0.45
homeOverlay.BorderSizePixel = 0
homeOverlay.ZIndex = 2
homeOverlay.Parent = PhoneHome
Instance.new("UICorner", homeOverlay).CornerRadius = UDim.new(0, 28)

local homeEars = Instance.new("ImageLabel")
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

-- Clock on home
local homeClock = Instance.new("TextLabel")
homeClock.Size = UDim2.new(1, 0, 0, 40)
homeClock.Position = UDim2.new(0, 0, 0, 50)
homeClock.BackgroundTransparency = 1
homeClock.Text = "00:00"
homeClock.TextColor3 = Color3.new(1,1,1)
homeClock.Font = Enum.Font.GothamBold
homeClock.TextSize = 36
homeClock.ZIndex = 5
homeClock.Parent = PhoneHome

task.spawn(function()
    while true do
        local t = os.date("*t")
        homeClock.Text = string.format("%02d:%02d", t.hour, t.min)
        task.wait(1)
    end
end)

-- FPS Label (se ativado)
fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 80, 0, 20)
fpsLabel.Position = UDim2.new(0, 12, 0, 95)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: --"
fpsLabel.TextColor3 = Color3.fromRGB(50, 205, 50)
fpsLabel.Font = Enum.Font.Code
fpsLabel.TextSize = 12
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.ZIndex = 5
fpsLabel.Visible = phoneSettings.fpsEnabled
fpsLabel.Parent = PhoneHome

task.spawn(function()
    local last = os.clock()
    local frames = 0
    while true do
        frames = frames + 1
        local now = os.clock()
        if now - last >= 1 then
            if fpsLabel then
                fpsLabel.Text = "FPS: " .. tostring(frames)
            end
            frames = 0
            last = now
        end
        RunService.RenderStepped:Wait()
    end
end)

-- App icons grid
local iconsFrame = Instance.new("Frame")
iconsFrame.Size = UDim2.new(1, -30, 0, 200)
iconsFrame.Position = UDim2.new(0, 15, 0, 130)
iconsFrame.BackgroundTransparency = 1
iconsFrame.ZIndex = 5
iconsFrame.Parent = PhoneHome

local iconsLayout = Instance.new("UIGridLayout")
iconsLayout.CellSize = UDim2.new(0, 60, 0, 70)
iconsLayout.CellPadding = UDim2.new(0, 12, 0, 10)
iconsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
iconsLayout.Parent = iconsFrame

local function createAppIcon(emoji, name, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 70)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 6
    btn.Parent = parent

    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0, 52, 0, 52)
    iconBg.Position = UDim2.new(0.5, -26, 0, 0)
    iconBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    iconBg.ZIndex = 6
    iconBg.Parent = btn
    Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 14)

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = emoji
    iconLabel.TextSize = 28
    iconLabel.ZIndex = 7
    iconLabel.Parent = iconBg

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.Position = UDim2.new(0, 0, 1, -16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.new(1,1,1)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 11
    nameLabel.ZIndex = 6
    nameLabel.Parent = btn

    return btn
end

local MusicAppIcon = createAppIcon("🎵", "Música", iconsFrame)
local StopwatchAppIcon = createAppIcon("⏱️", "Cronômetro", iconsFrame)
local CameraAppIcon = createAppIcon("📷", "Câmera", iconsFrame)
local GalleryAppIcon = createAppIcon("🖼️", "Galeria", iconsFrame)
local ConfigAppIcon = createAppIcon("⚙️", "Config", iconsFrame)

local homeNavBtn, homeBackBtn = createNavBar(PhoneHome)

-- Volume control (shared)
local volumeValue = 0.7
local volumeFrame = nil

local function attachVolumeTo(parent)
    if volumeFrame and volumeFrame.Parent then
        volumeFrame.Parent = parent
        return
    end
    -- volume is created later with music
end

-- ========== MUSIC APP ==========
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 440)
MainFrame.Position = UDim2.new(1, -300, 0.5, -220)
MainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 28)

local musicBezel = Instance.new("UIStroke")
musicBezel.Color = Color3.fromRGB(50, 205, 50)
musicBezel.Thickness = 6
musicBezel.Parent = MainFrame

local musicEars = Instance.new("ImageLabel")
musicEars.Size = UDim2.new(0, 340, 0, 95)
musicEars.Position = UDim2.new(0.5, -170, 0, -48)
musicEars.BackgroundTransparency = 1
musicEars.Image = "rbxassetid://108135642658853"
musicEars.ImageColor3 = Color3.fromRGB(50, 205, 50)
musicEars.ZIndex = 10
musicEars.Parent = MainFrame

local musicNotch = Instance.new("Frame")
musicNotch.Size = UDim2.new(0, 82, 0, 24)
musicNotch.Position = UDim2.new(0.5, -41, 0, 9)
musicNotch.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
musicNotch.BorderSizePixel = 0
musicNotch.Parent = MainFrame
Instance.new("UICorner", musicNotch).CornerRadius = UDim.new(1, 0)

local musicTitle = Instance.new("TextLabel")
musicTitle.Size = UDim2.new(1, 0, 0, 30)
musicTitle.Position = UDim2.new(0, 0, 0, 42)
musicTitle.BackgroundTransparency = 1
musicTitle.Text = "🎵 Música"
musicTitle.TextColor3 = Color3.new(1, 1, 1)
musicTitle.Font = Enum.Font.GothamBold
musicTitle.TextSize = 20
musicTitle.Parent = MainFrame

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0, 90, 0, 26)
ModeBtn.Position = UDim2.new(0, 12, 0, 78)
ModeBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
ModeBtn.Text = "Arquivo"
ModeBtn.TextColor3 = Color3.fromRGB(50, 205, 50)
ModeBtn.Font = Enum.Font.GothamBold
ModeBtn.TextSize = 12
ModeBtn.Parent = MainFrame
Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 8)

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -120, 0, 26)
SearchBox.Position = UDim2.new(0, 108, 0, 78)
SearchBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
SearchBox.PlaceholderText = "🔍 Buscar..."
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.new(1,1,1)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 12
SearchBox.Parent = MainFrame
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 8)

local IDInput = Instance.new("TextBox")
IDInput.Size = UDim2.new(1, -24, 0, 30)
IDInput.Position = UDim2.new(0, 12, 0, 78)
IDInput.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
IDInput.PlaceholderText = "Digite o Sound ID..."
IDInput.Text = ""
IDInput.TextColor3 = Color3.new(1,1,1)
IDInput.Font = Enum.Font.Gotham
IDInput.TextSize = 13
IDInput.Visible = false
IDInput.Parent = MainFrame
Instance.new("UICorner", IDInput).CornerRadius = UDim.new(0, 8)

local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Size = UDim2.new(1, -24, 0, 200)
ScrollList.Position = UDim2.new(0, 12, 0, 115)
ScrollList.BackgroundTransparency = 1
ScrollList.ScrollBarThickness = 3
ScrollList.ScrollBarImageColor3 = Color3.fromRGB(50, 205, 50)
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollList.Parent = MainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = ScrollList

local currentSound = nil
local isPaused = false
local currentTrackIndex = 0
local currentMode = "File"
local mp3List = {}
local shuffleMode = false
local repeatMode = false

local function formatTime(sec)
    sec = math.floor(sec or 0)
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%d:%02d", m, s)
end

local function play(asset, name, idx)
    if currentSound then
        currentSound:Stop()
        currentSound:Destroy()
    end
    currentSound = Instance.new("Sound")
    currentSound.SoundId = asset
    currentSound.Volume = volumeValue
    currentSound.Parent = Player.PlayerGui
    currentSound:Play()
    isPaused = false
    currentTrackIndex = idx or 0
    PlayBtn.Text = "⏸"
    NowPlaying.Text = name or "Tocando..."
end

local NowPlaying = Instance.new("TextLabel")
NowPlaying.Size = UDim2.new(1, -24, 0, 22)
NowPlaying.Position = UDim2.new(0, 12, 0, 320)
NowPlaying.BackgroundTransparency = 1
NowPlaying.Text = "Nenhuma música"
NowPlaying.TextColor3 = Color3.fromRGB(180, 180, 190)
NowPlaying.Font = Enum.Font.Gotham
NowPlaying.TextSize = 12
NowPlaying.TextTruncate = Enum.TextTruncate.AtEnd
NowPlaying.Parent = MainFrame

local TimeBarBg = Instance.new("Frame")
TimeBarBg.Size = UDim2.new(1, -24, 0, 4)
TimeBarBg.Position = UDim2.new(0, 12, 0, 345)
TimeBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
TimeBarBg.BorderSizePixel = 0
TimeBarBg.Parent = MainFrame
Instance.new("UICorner", TimeBarBg).CornerRadius = UDim.new(1, 0)

local TimeBarFill = Instance.new("Frame")
TimeBarFill.Size = UDim2.new(0, 0, 1, 0)
TimeBarFill.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
TimeBarFill.BorderSizePixel = 0
TimeBarFill.Parent = TimeBarBg
Instance.new("UICorner", TimeBarFill).CornerRadius = UDim.new(1, 0)

local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(1, -24, 0, 16)
TimeLabel.Position = UDim2.new(0, 12, 0, 352)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "0:00 / 0:00"
TimeLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
TimeLabel.Font = Enum.Font.Code
TimeLabel.TextSize = 11
TimeLabel.Parent = MainFrame

local controls = Instance.new("Frame")
controls.Size = UDim2.new(1, -24, 0, 40)
controls.Position = UDim2.new(0, 12, 0, 372)
controls.BackgroundTransparency = 1
controls.Parent = MainFrame

local PrevBtn = Instance.new("TextButton")
PrevBtn.Size = UDim2.new(0, 40, 0, 36)
PrevBtn.Position = UDim2.new(0, 20, 0, 0)
PrevBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
PrevBtn.Text = "⏮"
PrevBtn.TextColor3 = Color3.new(1,1,1)
PrevBtn.TextSize = 18
PrevBtn.Font = Enum.Font.GothamBold
PrevBtn.Parent = controls
Instance.new("UICorner", PrevBtn).CornerRadius = UDim.new(0, 10)

local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0, 50, 0, 36)
PlayBtn.Position = UDim2.new(0.5, -25, 0, 0)
PlayBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
PlayBtn.Text = "▶"
PlayBtn.TextColor3 = Color3.fromRGB(10,10,15)
PlayBtn.TextSize = 20
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = controls
Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 10)

local NextBtn = Instance.new("TextButton")
NextBtn.Size = UDim2.new(0, 40, 0, 36)
NextBtn.Position = UDim2.new(1, -60, 0, 0)
NextBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
NextBtn.Text = "⏭"
NextBtn.TextColor3 = Color3.new(1,1,1)
NextBtn.TextSize = 18
NextBtn.Font = Enum.Font.GothamBold
NextBtn.Parent = controls
Instance.new("UICorner", NextBtn).CornerRadius = UDim.new(0, 10)

local ShuffleBtn = Instance.new("TextButton")
ShuffleBtn.Size = UDim2.new(0, 36, 0, 28)
ShuffleBtn.Position = UDim2.new(0, 0, 0, 0)
ShuffleBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
ShuffleBtn.Text = "➡️"
ShuffleBtn.TextColor3 = Color3.new(1,1,1)
ShuffleBtn.TextSize = 14
ShuffleBtn.Parent = controls
Instance.new("UICorner", ShuffleBtn).CornerRadius = UDim.new(0, 8)

local RepeatBtn = Instance.new("TextButton")
RepeatBtn.Size = UDim2.new(0, 36, 0, 28)
RepeatBtn.Position = UDim2.new(1, -36, 0, 0)
RepeatBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
RepeatBtn.Text = "🔂"
RepeatBtn.TextColor3 = Color3.new(1,1,1)
RepeatBtn.TextSize = 14
RepeatBtn.Parent = controls
Instance.new("UICorner", RepeatBtn).CornerRadius = UDim.new(0, 8)

local musicNavBtn, musicBackBtn = createNavBar(MainFrame)

local function updateMusicList()
    for _, v in pairs(ScrollList:GetChildren()) do
        if v:IsA("TextButton") or v:IsA("Frame") then v:Destroy() end
    end
    local search = SearchBox.Text:lower()
    for i, track in ipairs(mp3List) do
        if search == "" or track.name:lower():find(search, 1, true) then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 36)
            btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
            btn.Text = "  " .. track.name
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = ScrollList
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            btn.MouseButton1Click:Connect(function()
                play(getcustomasset(track.path), track.name, i)
            end)
        end
    end
    task.wait()
    ScrollList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

local function refreshFiles()
    mp3List = {}
    local paths = {"PHONE/Music/", "PHONE/Music", "PHONE\\Music", "Music/", "Music"}
    local files = nil
    local success = false
    for _, p in ipairs(paths) do
        success, files = pcall(function() return listfiles(p) end)
        if success and type(files) == "table" and #files > 0 then break end
    end
    if success and type(files) == "table" then
        for _, file in ipairs(files) do
            local str = tostring(file)
            local lower = str:lower()
            if lower:match("%.mp3$") or lower:match("%.ogg$") or lower:match("%.wav$") or lower:match("%.flac$") then
                local name = str:match("([^/\\]+)$") or str
                name = name:gsub("%.%w+$", "")
                table.insert(mp3List, {name = name, path = file})
            end
        end
    end
    updateMusicList()
end

-- ========== STOPWATCH APP ==========
local StopwatchFrame = Instance.new("Frame")
StopwatchFrame.Name = "StopwatchFrame"
StopwatchFrame.Size = UDim2.new(0, 280, 0, 440)
StopwatchFrame.Position = UDim2.new(1, -300, 0.5, -220)
StopwatchFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
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
swEars.ZIndex = 10
swEars.Parent = StopwatchFrame

local swTitle = Instance.new("TextLabel")
swTitle.Size = UDim2.new(1, 0, 0, 35)
swTitle.Position = UDim2.new(0, 0, 0, 45)
swTitle.BackgroundTransparency = 1
swTitle.Text = "⏱️ Cronômetro"
swTitle.TextColor3 = Color3.new(1,1,1)
swTitle.Font = Enum.Font.GothamBold
swTitle.TextSize = 20
swTitle.Parent = StopwatchFrame

local swTimeLabel = Instance.new("TextLabel")
swTimeLabel.Size = UDim2.new(1, -20, 0, 60)
swTimeLabel.Position = UDim2.new(0, 10, 0, 120)
swTimeLabel.BackgroundTransparency = 1
swTimeLabel.Text = "0:00:00:00.<font size=\"18\">00</font>"
swTimeLabel.TextColor3 = Color3.new(1,1,1)
swTimeLabel.Font = Enum.Font.Code
swTimeLabel.TextSize = 28
swTimeLabel.RichText = true
swTimeLabel.Parent = StopwatchFrame

local swStartBtn = Instance.new("TextButton")
swStartBtn.Size = UDim2.new(0, 120, 0, 44)
swStartBtn.Position = UDim2.new(0.5, -130, 0, 220)
swStartBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
swStartBtn.Text = "▶ Iniciar"
swStartBtn.TextColor3 = Color3.fromRGB(10,10,15)
swStartBtn.Font = Enum.Font.GothamBold
swStartBtn.TextSize = 16
swStartBtn.Parent = StopwatchFrame
Instance.new("UICorner", swStartBtn).CornerRadius = UDim.new(0, 12)

local swResetBtn = Instance.new("TextButton")
swResetBtn.Size = UDim2.new(0, 120, 0, 44)
swResetBtn.Position = UDim2.new(0.5, 10, 0, 220)
swResetBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
swResetBtn.Text = "↺ Reset"
swResetBtn.TextColor3 = Color3.new(1,1,1)
swResetBtn.Font = Enum.Font.GothamBold
swResetBtn.TextSize = 16
swResetBtn.Parent = StopwatchFrame
Instance.new("UICorner", swResetBtn).CornerRadius = UDim.new(0, 12)

local swRunning = false
local swStartTime = 0
local swElapsed = 0
local swConnection = nil

local function formatStopwatch(t)
    local h = math.floor(t / 3600)
    local m = math.floor((t % 3600) / 60)
    local s = math.floor(t % 60)
    local cs = math.floor((t % 1) * 100)
    return string.format("%d:%02d:%02d:%02d.<font size=\"18\">%02d</font>", h, m, s, math.floor((t%1)*100)/1, cs)
end

local function updateStopwatchDisplay()
    local now = os.clock()
    if swRunning then
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

local swNavBtn, swBackBtn = createNavBar(StopwatchFrame)

-- ========== CAMERA APP ==========
local CameraFrame = Instance.new("Frame")
CameraFrame.Name = "CameraFrame"
CameraFrame.Size = UDim2.new(0, 280, 0, 440)
CameraFrame.Position = UDim2.new(1, -300, 0.5, -220)
CameraFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
CameraFrame.BorderSizePixel = 0
CameraFrame.Visible = false
CameraFrame.Active = true
CameraFrame.Draggable = true
CameraFrame.Parent = ScreenGui

Instance.new("UICorner", CameraFrame).CornerRadius = UDim.new(0, 28)

local camBezel = Instance.new("UIStroke")
camBezel.Color = Color3.fromRGB(50, 205, 50)
camBezel.Thickness = 6
camBezel.Parent = CameraFrame

local camEars = Instance.new("ImageLabel")
camEars.Size = UDim2.new(0, 340, 0, 95)
camEars.Position = UDim2.new(0.5, -170, 0, -48)
camEars.BackgroundTransparency = 1
camEars.Image = "rbxassetid://108135642658853"
camEars.ImageColor3 = Color3.fromRGB(50, 205, 50)
camEars.ZIndex = 10
camEars.Parent = CameraFrame

local camTitle = Instance.new("TextLabel")
camTitle.Size = UDim2.new(1, 0, 0, 30)
camTitle.Position = UDim2.new(0, 0, 0, 42)
camTitle.BackgroundTransparency = 1
camTitle.Text = "📷 Câmera"
camTitle.TextColor3 = Color3.new(1,1,1)
camTitle.Font = Enum.Font.GothamBold
camTitle.TextSize = 20
camTitle.Parent = CameraFrame

-- Viewfinder (simulado com a imagem atual do wallpaper / preview)
local viewfinder = Instance.new("Frame")
viewfinder.Size = UDim2.new(1, -24, 0, 280)
viewfinder.Position = UDim2.new(0, 12, 0, 80)
viewfinder.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
viewfinder.BorderSizePixel = 0
viewfinder.ClipsDescendants = true
viewfinder.Parent = CameraFrame
Instance.new("UICorner", viewfinder).CornerRadius = UDim.new(0, 16)

local viewfinderImg = Instance.new("ImageLabel")
viewfinderImg.Size = UDim2.new(1, 0, 1, 0)
viewfinderImg.BackgroundTransparency = 1
viewfinderImg.Image = homeBg.Image
viewfinderImg.ScaleType = Enum.ScaleType.Crop
viewfinderImg.Parent = viewfinder

local crosshairCam = Instance.new("Frame")
crosshairCam.Size = UDim2.new(0, 40, 0, 40)
crosshairCam.Position = UDim2.new(0.5, -20, 0.5, -20)
crosshairCam.BackgroundTransparency = 1
crosshairCam.Parent = viewfinder
local chStroke = Instance.new("UIStroke")
chStroke.Color = Color3.fromRGB(255, 255, 255)
chStroke.Thickness = 2
chStroke.Parent = crosshairCam
Instance.new("UICorner", crosshairCam).CornerRadius = UDim.new(1, 0)

local shutterBtn = Instance.new("TextButton")
shutterBtn.Size = UDim2.new(0, 70, 0, 70)
shutterBtn.Position = UDim2.new(0.5, -35, 1, -115)
shutterBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
shutterBtn.Text = ""
shutterBtn.Parent = CameraFrame
Instance.new("UICorner", shutterBtn).CornerRadius = UDim.new(1, 0)

local shutterInner = Instance.new("Frame")
shutterInner.Size = UDim2.new(0, 56, 0, 56)
shutterInner.Position = UDim2.new(0.5, -28, 0.5, -28)
shutterInner.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
shutterInner.Parent = shutterBtn
Instance.new("UICorner", shutterInner).CornerRadius = UDim.new(1, 0)

local camStatus = Instance.new("TextLabel")
camStatus.Size = UDim2.new(1, -20, 0, 20)
camStatus.Position = UDim2.new(0, 10, 1, -40)
camStatus.BackgroundTransparency = 1
camStatus.Text = "Toque no botão para tirar foto"
camStatus.TextColor3 = Color3.fromRGB(180, 180, 190)
camStatus.Font = Enum.Font.Gotham
camStatus.TextSize = 12
camStatus.Parent = CameraFrame

local camNavBtn, camBackBtn = createNavBar(CameraFrame)

local photoCount = 0
shutterBtn.MouseButton1Click:Connect(function()
    -- Animação de flash
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.new(1,1,1)
    flash.BackgroundTransparency = 0
    flash.ZIndex = 50
    flash.Parent = CameraFrame
    Instance.new("UICorner", flash).CornerRadius = UDim.new(0, 28)
    TweenService:Create(flash, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
    task.delay(0.4, function() flash:Destroy() end)

    -- Salva automaticamente em PHONE/Photos
    photoCount = photoCount + 1
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local fileName = "Foto_" .. timestamp .. ".png"
    local filePath = "PHONE/Photos/" .. fileName

    -- Tenta capturar via CaptureService se disponível, senão salva referência do wallpaper atual como "foto"
    local success = false
    pcall(function()
        -- Em muitos executors não há CaptureService real que salve arquivo.
        -- Salvamos um arquivo de metadados + usamos a imagem atual do viewfinder como placeholder.
        -- O usuário pode substituir depois. Também tentamos getcustomasset se possível.
        local meta = {
            name = fileName,
            takenAt = os.date("%Y-%m-%d %H:%M:%S"),
            wallpaperRef = homeBg.Image
        }
        writefile(filePath .. ".json", HttpService:JSONEncode(meta))
        -- Também tenta gravar um placeholder vazio para aparecer na galeria
        writefile(filePath, "") -- placeholder (alguns executors listam mesmo vazio)
        success = true
    end)

    if success then
        camStatus.Text = "✅ Foto salva: " .. fileName
        viewfinderImg.Image = homeBg.Image
        -- Atualiza a galeria se estiver aberta depois
        task.delay(1.5, function()
            camStatus.Text = "Toque no botão para tirar foto"
        end)
    else
        camStatus.Text = "❌ Erro ao salvar foto"
        task.delay(1.5, function()
            camStatus.Text = "Toque no botão para tirar foto"
        end)
    end
end)

-- ========== CONFIG APP ==========
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

createConfigToggle("FPS Counter", "Mostra o FPS na tela inicial do celular", phoneSettings.fpsEnabled, function(on)
    phoneSettings.fpsEnabled = on
    savedConfig.fpsEnabled = on
    saveConfig(savedConfig)
    if fpsLabel then
        fpsLabel.Visible = on
    end
end)

createConfigToggle("Lanterna do Celular", "Liga uma luz fraca na frente do personagem", phoneSettings.flashlightEnabled, function(on)
    phoneSettings.flashlightEnabled = on
    savedConfig.flashlightEnabled = on
    saveConfig(savedConfig)
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

-- Wallpaper section
local wallFrame = Instance.new("Frame")
wallFrame.Size = UDim2.new(1, 0, 0, 160)
wallFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
wallFrame.Parent = cfgScroll
Instance.new("UICorner", wallFrame).CornerRadius = UDim.new(0, 12)

local wallTitle = Instance.new("TextLabel")
wallTitle.Size = UDim2.new(1, -20, 0, 25)
wallTitle.Position = UDim2.new(0, 12, 0, 8)
wallTitle.BackgroundTransparency = 1
wallTitle.Text = "🖼️ Wallpaper"
wallTitle.TextColor3 = Color3.new(1,1,1)
wallTitle.Font = Enum.Font.GothamBold
wallTitle.TextSize = 14
wallTitle.TextXAlignment = Enum.TextXAlignment.Left
wallTitle.Parent = wallFrame

local wallIdBox = Instance.new("TextBox")
wallIdBox.Size = UDim2.new(1, -24, 0, 30)
wallIdBox.Position = UDim2.new(0, 12, 0, 40)
wallIdBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
wallIdBox.PlaceholderText = "rbxassetid:// ou ID numérico"
wallIdBox.Text = ""
wallIdBox.TextColor3 = Color3.new(1,1,1)
wallIdBox.Font = Enum.Font.Gotham
wallIdBox.TextSize = 12
wallIdBox.Parent = wallFrame
Instance.new("UICorner", wallIdBox).CornerRadius = UDim.new(0, 8)

local applyWallBtn = Instance.new("TextButton")
applyWallBtn.Size = UDim2.new(0, 110, 0, 28)
applyWallBtn.Position = UDim2.new(0, 12, 0, 80)
applyWallBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
applyWallBtn.Text = "Aplicar ID"
applyWallBtn.TextColor3 = Color3.fromRGB(10,10,15)
applyWallBtn.Font = Enum.Font.GothamBold
applyWallBtn.TextSize = 12
applyWallBtn.Parent = wallFrame
Instance.new("UICorner", applyWallBtn).CornerRadius = UDim.new(0, 8)

local fromPhotosBtn = Instance.new("TextButton")
fromPhotosBtn.Size = UDim2.new(0, 110, 0, 28)
fromPhotosBtn.Position = UDim2.new(0, 130, 0, 80)
fromPhotosBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
fromPhotosBtn.Text = "Das Fotos"
fromPhotosBtn.TextColor3 = Color3.new(1,1,1)
fromPhotosBtn.Font = Enum.Font.GothamBold
fromPhotosBtn.TextSize = 12
fromPhotosBtn.Parent = wallFrame
Instance.new("UICorner", fromPhotosBtn).CornerRadius = UDim.new(0, 8)

local wallStatus = Instance.new("TextLabel")
wallStatus.Size = UDim2.new(1, -24, 0, 30)
wallStatus.Position = UDim2.new(0, 12, 0, 115)
wallStatus.BackgroundTransparency = 1
wallStatus.Text = "Wallpaper atual salvo permanentemente"
wallStatus.TextColor3 = Color3.fromRGB(140, 140, 150)
wallStatus.Font = Enum.Font.Gotham
wallStatus.TextSize = 11
wallStatus.TextWrapped = true
wallStatus.Parent = wallFrame

applyWallBtn.MouseButton1Click:Connect(function()
    local txt = wallIdBox.Text:gsub("%s+", "")
    if txt == "" then return end
    local id = txt
    if not id:find("rbxassetid://") then
        id = "rbxassetid://" .. txt:gsub("%D", "")
    end
    homeBg.Image = id
    viewfinderImg.Image = id
    savedConfig.wallpaper = id
    savedConfig.wallpaperType = "asset"
    saveConfig(savedConfig)
    wallStatus.Text = "✅ Wallpaper salvo! (permanece ao reiniciar)"
    task.delay(2, function() wallStatus.Text = "Wallpaper atual salvo permanentemente" end)
end)

fromPhotosBtn.MouseButton1Click:Connect(function()
    -- Abre um seletor simples das fotos
    local photos = {}
    pcall(function()
        local files = listfiles("PHONE/Photos")
        if type(files) == "table" then
            for _, f in ipairs(files) do
                local s = tostring(f):lower()
                if s:match("%.png$") or s:match("%.jpg$") or s:match("%.jpeg$") or s:match("%.webp$") then
                    table.insert(photos, f)
                end
            end
        end
    end)
    if #photos == 0 then
        wallStatus.Text = "Nenhuma foto em PHONE/Photos"
        return
    end
    -- Usa a primeira por simplicidade (pode expandir para lista)
    local chosen = photos[1]
    local ok, asset = pcall(function() return getcustomasset(chosen) end)
    if ok and asset then
        homeBg.Image = asset
        viewfinderImg.Image = asset
        savedConfig.wallpaper = chosen
        savedConfig.wallpaperType = "custom"
        saveConfig(savedConfig)
        wallStatus.Text = "✅ Wallpaper da foto salvo!"
    else
        wallStatus.Text = "Erro ao carregar a foto"
    end
    task.delay(2, function() wallStatus.Text = "Wallpaper atual salvo permanentemente" end)
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

-- ========== GALERIA APP ==========
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

local photoList = {}
local filteredPhotoList = {}
local currentPhotoIndex = 0
local isInPhotoViewer = false
local currentApp = "home"

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
    if CameraFrame.Visible then currentPos = CameraFrame.Position end

    PhoneHome.Position = currentPos
    MainFrame.Position = currentPos
    StopwatchFrame.Position = currentPos
    ConfigFrame.Position = currentPos
    GalleryFrame.Position = currentPos
    CameraFrame.Position = currentPos

    PhoneHome.Visible = true
    MainFrame.Visible = false
    StopwatchFrame.Visible = false
    ConfigFrame.Visible = false
    GalleryFrame.Visible = false
    CameraFrame.Visible = false
    isMusicOpen = false
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
    if CameraFrame.Visible then currentPos = CameraFrame.Position end

    PhoneHome.Position = currentPos
    MainFrame.Position = currentPos
    StopwatchFrame.Position = currentPos
    ConfigFrame.Position = currentPos
    GalleryFrame.Position = currentPos
    CameraFrame.Position = currentPos

    PhoneHome.Visible = false
    MainFrame.Visible = true
    StopwatchFrame.Visible = false
    ConfigFrame.Visible = false
    GalleryFrame.Visible = false
    CameraFrame.Visible = false
    isMusicOpen = true

    refreshFiles()
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
    if CameraFrame.Visible then currentPos = CameraFrame.Position end

    PhoneHome.Position = currentPos
    MainFrame.Position = currentPos
    StopwatchFrame.Position = currentPos
    ConfigFrame.Position = currentPos
    GalleryFrame.Position = currentPos
    CameraFrame.Position = currentPos

    PhoneHome.Visible = false
    MainFrame.Visible = false
    StopwatchFrame.Visible = true
    ConfigFrame.Visible = false
    GalleryFrame.Visible = false
    CameraFrame.Visible = false
    isMusicOpen = false
end

local function openCameraApp()
    isInPhotoViewer = false
    exitPhotoViewer()

    currentApp = "camera"
    local currentPos = PhoneHome.Position
    if MainFrame.Visible then currentPos = MainFrame.Position end
    if StopwatchFrame.Visible then currentPos = StopwatchFrame.Position end
    if ConfigFrame.Visible then currentPos = ConfigFrame.Position end
    if GalleryFrame.Visible then currentPos = GalleryFrame.Position end
    if CameraFrame.Visible then currentPos = CameraFrame.Position end

    PhoneHome.Position = currentPos
    MainFrame.Position = currentPos
    StopwatchFrame.Position = currentPos
    ConfigFrame.Position = currentPos
    GalleryFrame.Position = currentPos
    CameraFrame.Position = currentPos

    PhoneHome.Visible = false
    MainFrame.Visible = false
    StopwatchFrame.Visible = false
    ConfigFrame.Visible = false
    GalleryFrame.Visible = false
    CameraFrame.Visible = true
    isMusicOpen = false

    viewfinderImg.Image = homeBg.Image
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
    if CameraFrame.Visible then currentPos = CameraFrame.Position end

    PhoneHome.Position = currentPos
    MainFrame.Position = currentPos
    StopwatchFrame.Position = currentPos
    ConfigFrame.Position = currentPos
    GalleryFrame.Position = currentPos
    CameraFrame.Position = currentPos

    PhoneHome.Visible = false
    MainFrame.Visible = false
    StopwatchFrame.Visible = false
    ConfigFrame.Visible = true
    GalleryFrame.Visible = false
    CameraFrame.Visible = false
    isMusicOpen = false
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
    if CameraFrame.Visible then currentPos = CameraFrame.Position end

    PhoneHome.Position = currentPos
    MainFrame.Position = currentPos
    StopwatchFrame.Position = currentPos
    ConfigFrame.Position = currentPos
    GalleryFrame.Position = currentPos
    CameraFrame.Position = currentPos

    PhoneHome.Visible = false
    MainFrame.Visible = false
    StopwatchFrame.Visible = false
    ConfigFrame.Visible = false
    GalleryFrame.Visible = true
    CameraFrame.Visible = false
    isMusicOpen = false

    refreshPhotos()
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
camNavBtn.MouseButton1Click:Connect(goHome)

homeBackBtn.MouseButton1Click:Connect(handleBack)
musicBackBtn.MouseButton1Click:Connect(handleBack)
swBackBtn.MouseButton1Click:Connect(handleBack)
cfgBackBtn.MouseButton1Click:Connect(handleBack)
galBackBtn.MouseButton1Click:Connect(handleBack)
camBackBtn.MouseButton1Click:Connect(handleBack)

MusicAppIcon.MouseButton1Click:Connect(openMusicApp)
StopwatchAppIcon.MouseButton1Click:Connect(openStopwatchApp)
CameraAppIcon.MouseButton1Click:Connect(openCameraApp)
ConfigAppIcon.MouseButton1Click:Connect(openConfigApp)
GalleryAppIcon.MouseButton1Click:Connect(openGalleryApp)

closePhone = function()
    isInPhotoViewer = false
    exitPhotoViewer()

    local target = UDim2.new(1, -300, 1, 80)
    local frames = {PhoneHome, MainFrame, StopwatchFrame, ConfigFrame, GalleryFrame, CameraFrame}
    for _, f in ipairs(frames) do
        if f.Visible then
            local tween = TweenService:Create(f, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = target})
            tween:Play()
            tween.Completed:Once(function()
                f.Visible = false
            end)
        end
    end

    isPhoneOpen = false
    isMusicOpen = false
    currentApp = "home"
    updateMovementStats()

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
        -- originalFOV kept for compatibility
    end

    removeExtraRoots()
    createSounds()

    Humanoid.JumpPower = SETTINGS.JumpPower
end

Player.CharacterRemoving:Connect(cleanup)
Player.CharacterAdded:Connect(onCharacterAdded)
if Player.Character then onCharacterAdded(Player.Character) end
