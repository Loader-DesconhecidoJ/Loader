local selectedItems = {
    TzesPhone = true
}

local menuConfirmed = true -- jÃ¡ confirmado, sÃ³ o phone

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
-- SCRIPT PRINCIPAL (sÃ³ Phone)
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
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local HapticService = game:GetService("HapticService")
local Lighting = game:GetService("Lighting")

local isTouchDevice = UserInputService.TouchEnabled

local phoneSettings = {
    fpsEnabled = false,
    flashlightEnabled = false,
    joinTime = os.clock()
}

local fpsLabel = nil
local phoneFlashlight = nil

-- Estados de "equipamento" via hotbar (sem Tools)
local equippedItem = nil          -- "TzesPhone" | nil

-- =========================================================
-- HAPTIC FEEDBACK (vibraÃ§Ã£o mobile)
-- =========================================================
local function playHaptic(intensity)
    intensity = intensity or 0.4
    if isTouchDevice then
        pcall(function()
            if HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1) then
                HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, intensity)
                task.delay(0.08, function()
                    pcall(function()
                        HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 0)
                    end)
                end)
            end
            -- fallback para dispositivos que suportam via UserInputService
            if UserInputService.VibrationEnabled then
                -- alguns executors / dispositivos respeitam isso
            end
        end)
    end
end

-- =========================================================
-- BLUR DE FUNDO quando o telefone estÃ¡ aberto
-- =========================================================
local phoneBlur = Instance.new("BlurEffect")
phoneBlur.Name = "TzePhoneBlur"
phoneBlur.Size = 0
phoneBlur.Enabled = false
phoneBlur.Parent = Lighting

local function enablePhoneBlur()
    phoneBlur.Enabled = true
    TweenService:Create(phoneBlur, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = 18
    }):Play()
end

local function disablePhoneBlur()
    local t = TweenService:Create(phoneBlur, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = 0
    })
    t:Play()
    t.Completed:Once(function()
        phoneBlur.Enabled = false
    end)
end

local function cleanup()
    if phoneFlashlight then
        phoneFlashlight:Destroy()
        phoneFlashlight = nil
    end
    if isPhoneOpen and closePhone then
        closePhone()
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
-- CUSTOM HOTBAR CLEAN (estilo iPhone / Android) - sÃ³ Phone
-- =========================================================
local HotbarGui = Instance.new("ScreenGui")
HotbarGui.Name = "TzeCustomHotbar"
HotbarGui.ResetOnSpawn = false
HotbarGui.IgnoreGuiInset = true
HotbarGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HotbarGui.Parent = game:GetService("CoreGui")

local HotbarFrame = Instance.new("Frame")
HotbarFrame.Name = "HotbarFrame"
HotbarFrame.Size = UDim2.new(0, 58, 0, 58)
HotbarFrame.Position = UDim2.new(1, -72, 1, -90)
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
    {Name = "TzesPhone",  Emoji = "ðŸ“±", Color = Color3.fromRGB(50, 205, 50),   ToolName = "TzesPhone"}
}

local slotButtons = {}
local activeSlots = {}

for _, data in ipairs(slotsData) do
    if selectedItems[data.ToolName] then
        table.insert(activeSlots, data)
    end
end

-- =========================================================
-- FUNÃ‡Ã•ES DE ATIVAÃ‡ÃƒO / DESATIVAÃ‡ÃƒO (sem Tools)
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
        -- JÃ¡ estÃ¡ equipado â†’ desequipa
        unequipAll()
        return
    end

    -- Desequipa o anterior
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
    slot.Size = UDim2.new(0, 50, 0, 50)
    slot.Position = UDim2.new(0, 4, 0, 4)
    slot.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    slot.BorderSizePixel = 0
    slot.Text = ""
    slot.AutoButtonColor = false
    slot.Parent = HotbarFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = slot

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 90)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = slot

    -- sombra suave
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 12, 1, 12)
    shadow.Position = UDim2.new(0, -6, 0, -4)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = slot.ZIndex - 1
    shadow.Parent = slot

    local emoji = Instance.new("TextLabel")
    emoji.Size = UDim2.new(1, 0, 1, 0)
    emoji.BackgroundTransparency = 1
    emoji.Text = data.Emoji
    emoji.TextSize = 24
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
    selStroke.Color = Color3.fromRGB(50, 205, 50)
    selStroke.Thickness = 2.5
    selStroke.Parent = selected
    Instance.new("UICorner", selected).CornerRadius = UDim.new(0, 16)

    slot.MouseEnter:Connect(function()
        TweenService:Create(slot, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(35, 35, 42),
            Size = UDim2.new(0, 54, 0, 54)
        }):Play()
    end)

    slot.MouseLeave:Connect(function()
        TweenService:Create(slot, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(22, 22, 28),
            Size = UDim2.new(0, 50, 0, 50)
        }):Play()
    end)

    slot.MouseButton1Click:Connect(function()
        playHaptic(0.35)
        equipItem(data.ToolName)
    end)

    slotButtons[data.ToolName] = {button = slot, selected = selected, data = data}
    return slot
end

for i, data in ipairs(activeSlots) do
    createSlot(i, data)
end

if #activeSlots > 0 then
    HotbarFrame.Size = UDim2.new(0, 58, 0, 58)
    HotbarFrame.Position = UDim2.new(1, -72, 1, -90)
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
-- TZE PHONE SYSTEM + MUSIC + CRONÃ”METRO + CONFIG + GALERIA
-- (Redesign moderno iPhone / Android)
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
    navBar.Size = UDim2.new(1, -24, 0, 34)
    navBar.Position = UDim2.new(0, 12, 1, -42)
    navBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    navBar.BackgroundTransparency = 0.55
    navBar.BorderSizePixel = 0
    navBar.ZIndex = 20
    navBar.Parent = parent
    Instance.new("UICorner", navBar).CornerRadius = UDim.new(0, 18)

    -- â—€  um pouco mais para a DIREITA
    local backBtn = Instance.new("TextButton")
    backBtn.Name = "BackBtn"
    backBtn.Size = UDim2.new(0, 32, 0, 32)
    backBtn.Position = UDim2.new(0, 18, 0.5, -16)
    backBtn.BackgroundTransparency = 1
    backBtn.Text = "â€¹"
    backBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    backBtn.TextSize = 28
    backBtn.Font = Enum.Font.GothamBold
    backBtn.ZIndex = 21
    backBtn.Parent = navBar

    -- â—¯  fica no MEIO
    local homeBtn = Instance.new("TextButton")
    homeBtn.Name = "HomeCircle"
    homeBtn.Size = UDim2.new(0, 32, 0, 32)
    homeBtn.Position = UDim2.new(0.5, -16, 0.5, -16)
    homeBtn.BackgroundTransparency = 1
    homeBtn.Text = "â—‹"
    homeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    homeBtn.TextSize = 22
    homeBtn.Font = Enum.Font.GothamBold
    homeBtn.ZIndex = 21
    homeBtn.Parent = navBar

    local function addClickAnim(btn)
        btn.MouseButton1Down:Connect(function()
            playHaptic(0.25)
            TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextSize = btn.TextSize - 4
            }):Play()
        end)
        btn.MouseButton1Up:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                TextSize = (btn.Name == "BackBtn") and 28 or 22
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {
                TextSize = (btn.Name == "BackBtn") and 28 or 22
            }):Play()
        end)
    end
    addClickAnim(backBtn)
    addClickAnim(homeBtn)

    return homeBtn, backBtn
end

-- ========== PHONE HOME SCREEN (posicionado Ã  DIREITA) - REDESIGN MODERNO ==========
local PhoneHome = Instance.new("Frame")
PhoneHome.Name = "PhoneHome"
PhoneHome.Size = UDim2.new(0, 290, 0, 560)
PhoneHome.Position = UDim2.new(1, -310, 0.5, -280)
PhoneHome.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
PhoneHome.BorderSizePixel = 0
PhoneHome.Visible = false
PhoneHome.Active = true
PhoneHome.Draggable = true
PhoneHome.Parent = ScreenGui

Instance.new("UICorner", PhoneHome).CornerRadius = UDim.new(0, 42)

-- Bezel moderno fino
local homeBezel = Instance.new("UIStroke")
homeBezel.Color = Color3.fromRGB(45, 45, 55)
homeBezel.Thickness = 5
homeBezel.Parent = PhoneHome

-- Dynamic Island falsa (estilo iPhone 14/15/16)
local dynamicIsland = Instance.new("Frame")
dynamicIsland.Name = "DynamicIsland"
dynamicIsland.Size = UDim2.new(0, 118, 0, 32)
dynamicIsland.Position = UDim2.new(0.5, -59, 0, 14)
dynamicIsland.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dynamicIsland.BorderSizePixel = 0
dynamicIsland.ZIndex = 15
dynamicIsland.Parent = PhoneHome
Instance.new("UICorner", dynamicIsland).CornerRadius = UDim.new(1, 0)

-- Ponto da cÃ¢mera dentro da Dynamic Island
local islandCam = Instance.new("Frame")
islandCam.Size = UDim2.new(0, 10, 0, 10)
islandCam.Position = UDim2.new(1, -22, 0.5, -5)
islandCam.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
islandCam.BorderSizePixel = 0
islandCam.ZIndex = 16
islandCam.Parent = dynamicIsland
Instance.new("UICorner", islandCam).CornerRadius = UDim.new(1, 0)

local islandCamInner = Instance.new("Frame")
islandCamInner.Size = UDim2.new(0, 5, 0, 5)
islandCamInner.Position = UDim2.new(0.5, -2.5, 0.5, -2.5)
islandCamInner.BackgroundColor3 = Color3.fromRGB(40, 60, 90)
islandCamInner.BorderSizePixel = 0
islandCamInner.ZIndex = 17
islandCamInner.Parent = islandCam
Instance.new("UICorner", islandCamInner).CornerRadius = UDim.new(1, 0)

-- Wallpaper
local homeBg = Instance.new("ImageLabel")
homeBg.Name = "Wallpaper"
homeBg.Size = UDim2.new(1, 0, 1, 0)
homeBg.BackgroundTransparency = 1
homeBg.Image = "rbxassetid://12506271392"
homeBg.ScaleType = Enum.ScaleType.Crop
homeBg.ZIndex = 1
homeBg.Parent = PhoneHome
Instance.new("UICorner", homeBg).CornerRadius = UDim.new(0, 42)

local homeOverlay = Instance.new("Frame")
homeOverlay.Size = UDim2.new(1, 0, 1, 0)
homeOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
homeOverlay.BackgroundTransparency = 0.42
homeOverlay.BorderSizePixel = 0
homeOverlay.ZIndex = 2
homeOverlay.Parent = PhoneHome
Instance.new("UICorner", homeOverlay).CornerRadius = UDim.new(0, 42)

-- Status bar
local homeStatus = Instance.new("TextLabel")
homeStatus.Name = "StatusClock"
homeStatus.Size = UDim2.new(0.5, -10, 0, 22)
homeStatus.Position = UDim2.new(0, 22, 0, 52)
homeStatus.BackgroundTransparency = 1
homeStatus.Text = os.date("%H:%M")
homeStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
homeStatus.Font = Enum.Font.GothamBold
homeStatus.TextSize = 15
homeStatus.TextXAlignment = Enum.TextXAlignment.Left
homeStatus.ZIndex = 5
homeStatus.Parent = PhoneHome

fpsLabel = Instance.new("TextLabel")
fpsLabel.Name = "FPSLabel"
fpsLabel.Size = UDim2.new(0.5, -10, 0, 22)
fpsLabel.Position = UDim2.new(0.5, 0, 0, 52)
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
homeTitle.Size = UDim2.new(1, 0, 0, 28)
homeTitle.Position = UDim2.new(0, 0, 0, 88)
homeTitle.BackgroundTransparency = 1
homeTitle.Text = "Apps"
homeTitle.TextColor3 = Color3.new(1, 1, 1)
homeTitle.Font = Enum.Font.GothamBold
homeTitle.TextSize = 22
homeTitle.ZIndex = 5
homeTitle.Parent = PhoneHome

local appsContainer = Instance.new("Frame")
appsContainer.Size = UDim2.new(1, -36, 0, 280)
appsContainer.Position = UDim2.new(0, 18, 0, 128)
appsContainer.BackgroundTransparency = 1
appsContainer.ZIndex = 5
appsContainer.Parent = PhoneHome

local function createAppIcon(name, emoji, color, pos)
    local icon = Instance.new("TextButton")
    icon.Size = UDim2.new(0, 72, 0, 92)
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
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 18)

    -- sombra suave no Ã­cone
    local iconShadow = Instance.new("ImageLabel")
    iconShadow.Size = UDim2.new(1, 10, 1, 10)
    iconShadow.Position = UDim2.new(0, -5, 0, -3)
    iconShadow.BackgroundTransparency = 1
    iconShadow.Image = "rbxassetid://1316045217"
    iconShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    iconShadow.ImageTransparency = 0.75
    iconShadow.ScaleType = Enum.ScaleType.Slice
    iconShadow.SliceCenter = Rect.new(10, 10, 118, 118)
    iconShadow.ZIndex = 5
    iconShadow.Parent = bg

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

    icon.MouseButton1Click:Connect(function()
        playHaptic(0.3)
    end)

    return icon
end

local MusicAppIcon = createAppIcon("MÃºsica", "ðŸŽµ", Color3.fromRGB(0, 180, 255), UDim2.new(0, 8, 0, 0))
local StopwatchAppIcon = createAppIcon("CronÃ´metro", "â±ï¸", Color3.fromRGB(255, 140, 30), UDim2.new(0, 92, 0, 0))
local ConfigAppIcon = createAppIcon("Config", "âš™ï¸", Color3.fromRGB(120, 120, 130), UDim2.new(0, 176, 0, 0))
local GalleryAppIcon = createAppIcon("Galeria", "ðŸ–¼ï¸", Color3.fromRGB(180, 80, 220), UDim2.new(0, 8, 0, 110))

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
VolumeFrame.Size = UDim2.new(0, 18, 0, 110)
VolumeFrame.Position = UDim2.new(0, -26, 0.5, -140)
VolumeFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
VolumeFrame.BackgroundTransparency = 0.1
VolumeFrame.BorderSizePixel = 0
VolumeFrame.ZIndex = 30
VolumeFrame.Visible = false
VolumeFrame.Parent = ScreenGui
Instance.new("UICorner", VolumeFrame).CornerRadius = UDim.new(0, 12)
local volFrameStroke = Instance.new("UIStroke")
volFrameStroke.Color = Color3.fromRGB(60, 60, 70)
volFrameStroke.Thickness = 1.2
volFrameStroke.Parent = VolumeFrame

local VolUpBtn = Instance.new("TextButton")
VolUpBtn.Name = "VolUp"
VolUpBtn.Size = UDim2.new(1, -4, 0, 48)
VolUpBtn.Position = UDim2.new(0, 2, 0, 4)
VolUpBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
VolUpBtn.Text = "ðŸ”Š"
VolUpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VolUpBtn.Font = Enum.Font.GothamBold
VolUpBtn.TextSize = 14
VolUpBtn.ZIndex = 31
VolUpBtn.Parent = VolumeFrame
Instance.new("UICorner", VolUpBtn).CornerRadius = UDim.new(0, 8)

local VolDownBtn = Instance.new("TextButton")
VolDownBtn.Name = "VolDown"
VolDownBtn.Size = UDim2.new(1, -4, 0, 48)
VolDownBtn.Position = UDim2.new(0, 2, 0, 58)
VolDownBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
VolDownBtn.Text = "ðŸ”‰"
VolDownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VolDownBtn.Font = Enum.Font.GothamBold
VolDownBtn.TextSize = 14
VolDownBtn.ZIndex = 31
VolDownBtn.Parent = VolumeFrame
Instance.new("UICorner", VolDownBtn).CornerRadius = UDim.new(0, 8)

VolUpBtn.MouseButton1Click:Connect(function()
    playHaptic(0.2)
    currentVolume = math.clamp(currentVolume + 0.1, 0, 1)
    if currentSound then
        currentSound.Volume = currentVolume
    end
end)

VolDownBtn.MouseButton1Click:Connect(function()
    playHaptic(0.2)
    currentVolume = math.clamp(currentVolume - 0.1, 0, 1)
    if currentSound then
        currentSound.Volume = currentVolume
    end
end)

local function attachVolumeTo(frame)
    if not frame then return end
    VolumeFrame.Parent = frame
    VolumeFrame.Position = UDim2.new(0, -26, 0.5, -140)
    VolumeFrame.BackgroundTransparency = 0.1
    VolumeFrame.Visible = true
end

-- ========== MUSIC PLAYER (direita) ==========
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 290, 0, 560)
MainFrame.Position = UDim2.new(1, -310, 0.5, -280)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 42)

local bezelStroke = Instance.new("UIStroke")
bezelStroke.Color = Color3.fromRGB(45, 45, 55)
bezelStroke.Thickness = 5
bezelStroke.Parent = MainFrame

-- Dynamic Island no Music tambÃ©m
local musicIsland = Instance.new("Frame")
musicIsland.Name = "DynamicIsland"
musicIsland.Size = UDim2.new(0, 118, 0, 32)
musicIsland.Position = UDim2.new(0.5, -59, 0, 14)
musicIsland.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
musicIsland.BorderSizePixel = 0
musicIsland.ZIndex = 15
musicIsland.Parent = MainFrame
Instance.new("UICorner", musicIsland).CornerRadius = UDim.new(1, 0)

local musicIslandCam = Instance.new("Frame")
musicIslandCam.Size = UDim2.new(0, 10, 0, 10)
musicIslandCam.Position = UDim2.new(1, -22, 0.5, -5)
musicIslandCam.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
musicIslandCam.BorderSizePixel = 0
musicIslandCam.ZIndex = 16
musicIslandCam.Parent = musicIsland
Instance.new("UICorner", musicIslandCam).CornerRadius = UDim.new(1, 0)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.Position = UDim2.new(0, 0, 0, 52)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0, 110, 0, 30)
ModeBtn.Position = UDim2.new(1, -126, 0.5, -15)
ModeBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
ModeBtn.Text = "Arquivo"
ModeBtn.TextColor3 = Color3.fromRGB(50, 205, 50)
ModeBtn.Font = Enum.Font.GothamBold
ModeBtn.TextSize = 12
ModeBtn.Parent = TopBar
Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 12)
local modeStroke = Instance.new("UIStroke")
modeStroke.Color = Color3.fromRGB(50, 205, 50)
modeStroke.Thickness = 1.2
modeStroke.Parent = ModeBtn

local MusicTitle = Instance.new("TextLabel")
MusicTitle.Size = UDim2.new(0, 120, 0, 28)
MusicTitle.Position = UDim2.new(0, 18, 0.5, -14)
MusicTitle.BackgroundTransparency = 1
MusicTitle.Text = "MÃºsica"
MusicTitle.TextColor3 = Color3.new(1, 1, 1)
MusicTitle.Font = Enum.Font.GothamBold
MusicTitle.TextSize = 18
MusicTitle.TextXAlignment = Enum.TextXAlignment.Left
MusicTitle.Parent = TopBar

local NowPlayingCard = Instance.new("Frame")
NowPlayingCard.Size = UDim2.new(1, -28, 0, 128)
NowPlayingCard.Position = UDim2.new(0, 14, 0, 102)
NowPlayingCard.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
NowPlayingCard.BorderSizePixel = 0
NowPlayingCard.Parent = MainFrame
Instance.new("UICorner", NowPlayingCard).CornerRadius = UDim.new(0, 20)
local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(50, 50, 60)
cardStroke.Thickness = 1
cardStroke.Parent = NowPlayingCard

local AlbumArt = Instance.new("Frame")
AlbumArt.Size = UDim2.new(0, 64, 0, 64)
AlbumArt.Position = UDim2.new(0, 16, 0.5, -32)
AlbumArt.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
AlbumArt.BorderSizePixel = 0
AlbumArt.Parent = NowPlayingCard
Instance.new("UICorner", AlbumArt).CornerRadius = UDim.new(0, 14)

local AlbumIcon = Instance.new("TextLabel")
AlbumIcon.Size = UDim2.new(1, 0, 1, 0)
AlbumIcon.BackgroundTransparency = 1
AlbumIcon.Text = "ðŸŽµ"
AlbumIcon.TextSize = 30
AlbumIcon.Parent = AlbumArt

local TrackName = Instance.new("TextLabel")
TrackName.Size = UDim2.new(1, -100, 0, 24)
TrackName.Position = UDim2.new(0, 92, 0, 22)
TrackName.BackgroundTransparency = 1
TrackName.Text = "Nenhuma mÃºsica"
TrackName.TextColor3 = Color3.new(1, 1, 1)
TrackName.Font = Enum.Font.GothamBold
TrackName.TextSize = 15
TrackName.TextXAlignment = Enum.TextXAlignment.Left
TrackName.TextTruncate = Enum.TextTruncate.AtEnd
TrackName.Parent = NowPlayingCard

local TrackSub = Instance.new("TextLabel")
TrackSub.Size = UDim2.new(1, -100, 0, 18)
TrackSub.Position = UDim2.new(0, 92, 0, 48)
TrackSub.BackgroundTransparency = 1
TrackSub.Text = "Toque para ouvir"
TrackSub.TextColor3 = Color3.fromRGB(140, 140, 155)
TrackSub.Font = Enum.Font.Gotham
TrackSub.TextSize = 12
TrackSub.TextXAlignment = Enum.TextXAlignment.Left
TrackSub.Parent = NowPlayingCard

local TimeBarBG = Instance.new("Frame")
TimeBarBG.Size = UDim2.new(1, -32, 0, 5)
TimeBarBG.Position = UDim2.new(0, 16, 1, -30)
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
TimeLabel.Size = UDim2.new(1, -32, 0, 14)
TimeLabel.Position = UDim2.new(0, 16, 1, -20)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "00:00 / 00:00"
TimeLabel.TextColor3 = Color3.fromRGB(130, 130, 145)
TimeLabel.Font = Enum.Font.Code
TimeLabel.TextSize = 10
TimeLabel.TextXAlignment = Enum.TextXAlignment.Right
TimeLabel.Parent = NowPlayingCard

local Controls = Instance.new("Frame")
Controls.Size = UDim2.new(1, -28, 0, 56)
Controls.Position = UDim2.new(0, 14, 0, 246)
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
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(50, 50, 60)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn
    btn.MouseButton1Click:Connect(function()
        playHaptic(0.25)
    end)
    return btn
end

local ShuffleBtn = createBtn("ðŸ”€", UDim2.new(0, 0, 0.5, -18), UDim2.new(0, 44, 0, 36))
local PrevBtn = createBtn("â®", UDim2.new(0.22, -8, 0.5, -18), UDim2.new(0, 48, 0, 36))
local PlayBtn = createBtn("â–¶", UDim2.new(0.5, -26, 0.5, -24), UDim2.new(0, 52, 0, 48))
PlayBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
PlayBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
local NextBtn = createBtn("â­", UDim2.new(0.78, -40, 0.5, -18), UDim2.new(0, 48, 0, 36))
local RepeatBtn = createBtn("ðŸ”", UDim2.new(1, -44, 0.5, -18), UDim2.new(0, 44, 0, 36))

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -28, 0, 34)
SearchBox.Position = UDim2.new(0, 14, 0, 316)
SearchBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
SearchBox.PlaceholderText = "ðŸ” Pesquisar mÃºsica..."
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.new(1, 1, 1)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 13
SearchBox.Parent = MainFrame
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 12)
local searchStroke = Instance.new("UIStroke")
searchStroke.Color = Color3.fromRGB(50, 50, 60)
searchStroke.Thickness = 1
searchStroke.Parent = SearchBox

local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Size = UDim2.new(1, -28, 0, 120)
ScrollList.Position = UDim2.new(0, 14, 0, 360)
ScrollList.BackgroundTransparency = 1
ScrollList.ScrollBarThickness = 3
ScrollList.ScrollBarImageColor3 = Color3.fromRGB(50, 205, 50)
ScrollList.Parent = MainFrame
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = ScrollList

local IDInput = Instance.new("TextBox")
IDInput.Size = UDim2.new(1, -28, 0, 36)
IDInput.Position = UDim2.new(0, 14, 0, 360)
IDInput.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
IDInput.PlaceholderText = "Digite o Sound ID do Roblox..."
IDInput.Text = ""
IDInput.TextColor3 = Color3.new(1, 1, 1)
IDInput.Visible = false
IDInput.Parent = MainFrame
Instance.new("UICorner", IDInput).CornerRadius = UDim.new(0, 12)
local idStroke = Instance.new("UIStroke")
idStroke.Color = Color3.fromRGB(50, 50, 60)
idStroke.Thickness = 1
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
    PlayBtn.Text = "â¸"
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
        Instance.new("UICorner", emptyFrame).CornerRadius = UDim.new(0, 12)
        
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 1, 0)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = searchText == "" and "ðŸ“ Coloque .mp3 em PHONE/Music" or "ðŸ” Nenhuma mÃºsica encontrada"
        emptyLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
        emptyLabel.TextSize = 12
        emptyLabel.Parent = emptyFrame
    else
        for idx, music in ipairs(filteredList) do
            local btnFrame = Instance.new("Frame")
            btnFrame.Size = UDim2.new(1, 0, 0, 40)
            btnFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
            btnFrame.Parent = ScrollList
            Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 12)
            
            local t = Instance.new("TextButton")
            t.Size = UDim2.new(1, 0, 1, 0)
            t.BackgroundTransparency = 1
            t.Text = "  ðŸŽµ  " .. music.name
            t.TextColor3 = Color3.new(1,1,1)
            t.TextXAlignment = Enum.TextXAlignment.Left
            t.TextSize = 13
            t.Font = Enum.Font.Gotham
            t.Parent = btnFrame
            
            t.MouseButton1Click:Connect(function()
                playHaptic(0.25)
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

-- ========== CRONÃ”METRO (direita) ==========
local StopwatchFrame = Instance.new("Frame")
StopwatchFrame.Name = "StopwatchFrame"
StopwatchFrame.Size = UDim2.new(0, 290, 0, 560)
StopwatchFrame.Position = UDim2.new(1, -310, 0.5, -280)
StopwatchFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
StopwatchFrame.BorderSizePixel = 0
StopwatchFrame.Visible = false
StopwatchFrame.Active = true
StopwatchFrame.Draggable = true
StopwatchFrame.Parent = ScreenGui

Instance.new("UICorner", StopwatchFrame).CornerRadius = UDim.new(0, 42)

local swBezel = Instance.new("UIStroke")
swBezel.Color = Color3.fromRGB(45, 45, 55)
swBezel.Thickness = 5
swBezel.Parent = StopwatchFrame

local swIsland = Instance.new("Frame")
swIsland.Name = "DynamicIsland"
swIsland.Size = UDim2.new(0, 118, 0, 32)
swIsland.Position = UDim2.new(0.5, -59, 0, 14)
swIsland.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
swIsland.BorderSizePixel = 0
swIsland.ZIndex = 15
swIsland.Parent = StopwatchFrame
Instance.new("UICorner", swIsland).CornerRadius = UDim.new(1, 0)

local swTitle = Instance.new("TextLabel")
swTitle.Size = UDim2.new(1, 0, 0, 30)
swTitle.Position = UDim2.new(0, 0, 0, 60)
swTitle.BackgroundTransparency = 1
swTitle.Text = "â±ï¸ CronÃ´metro"
swTitle.TextColor3 = Color3.new(1, 1, 1)
swTitle.Font = Enum.Font.GothamBold
swTitle.TextSize = 20
swTitle.Parent = StopwatchFrame

local swTimeLabel = Instance.new("TextLabel")
swTimeLabel.Size = UDim2.new(1, -40, 0, 90)
swTimeLabel.Position = UDim2.new(0, 20, 0, 140)
swTimeLabel.BackgroundTransparency = 1
swTimeLabel.Text = "0:00:00:00.<font size=\"18\">00</font>"
swTimeLabel.TextColor3 = Color3.fromRGB(50, 205, 50)
swTimeLabel.Font = Enum.Font.Code
swTimeLabel.TextSize = 34
swTimeLabel.RichText = true
swTimeLabel.Parent = StopwatchFrame

local swStartBtn = Instance.new("TextButton")
swStartBtn.Size = UDim2.new(0, 110, 0, 52)
swStartBtn.Position = UDim2.new(0.5, -120, 0, 260)
swStartBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
swStartBtn.Text = "â–¶ Iniciar"
swStartBtn.TextColor3 = Color3.new(0, 0, 0)
swStartBtn.Font = Enum.Font.GothamBold
swStartBtn.TextSize = 16
swStartBtn.Parent = StopwatchFrame
Instance.new("UICorner", swStartBtn).CornerRadius = UDim.new(0, 16)

local swResetBtn = Instance.new("TextButton")
swResetBtn.Size = UDim2.new(0, 110, 0, 52)
swResetBtn.Position = UDim2.new(0.5, 10, 0, 260)
swResetBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
swResetBtn.Text = "â†º Reset"
swResetBtn.TextColor3 = Color3.new(1, 1, 1)
swResetBtn.Font = Enum.Font.GothamBold
swResetBtn.TextSize = 16
swResetBtn.Parent = StopwatchFrame
Instance.new("UICorner", swResetBtn).CornerRadius = UDim.new(0, 16)

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
    playHaptic(0.3)
    if swRunning then
        swElapsed = swElapsed + (os.clock() - swStartTime)
        swRunning = false
        swStartBtn.Text = "â–¶ Iniciar"
        swStartBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
        if swConnection then swConnection:Disconnect() swConnection = nil end
    else
        swStartTime = os.clock()
        swRunning = true
        swStartBtn.Text = "â¸ Pausar"
        swStartBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 30)
        if swConnection then swConnection:Disconnect() end
        swConnection = RunService.RenderStepped:Connect(updateStopwatchDisplay)
    end
end)

swResetBtn.MouseButton1Click:Connect(function()
    playHaptic(0.25)
    swRunning = false
    swElapsed = 0
    swStartTime = 0
    swTimeLabel.Text = "0:00:00:00.<font size=\"18\">00</font>"
    swStartBtn.Text = "â–¶ Iniciar"
    swStartBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
    if swConnection then swConnection:Disconnect() swConnection = nil end
end)

-- ========== CONFIG APP (direita) ==========
local ConfigFrame = Instance.new("Frame")
ConfigFrame.Name = "ConfigFrame"
ConfigFrame.Size = UDim2.new(0, 290, 0, 560)
ConfigFrame.Position = UDim2.new(1, -310, 0.5, -280)
ConfigFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
ConfigFrame.BorderSizePixel = 0
ConfigFrame.Visible = false
ConfigFrame.Active = true
ConfigFrame.Draggable = true
ConfigFrame.Parent = ScreenGui

Instance.new("UICorner", ConfigFrame).CornerRadius = UDim.new(0, 42)

local cfgBezel = Instance.new("UIStroke")
cfgBezel.Color = Color3.fromRGB(45, 45, 55)
cfgBezel.Thickness = 5
cfgBezel.Parent = ConfigFrame

local cfgIsland = Instance.new("Frame")
cfgIsland.Name = "DynamicIsland"
cfgIsland.Size = UDim2.new(0, 118, 0, 32)
cfgIsland.Position = UDim2.new(0.5, -59, 0, 14)
cfgIsland.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
cfgIsland.BorderSizePixel = 0
cfgIsland.ZIndex = 15
cfgIsland.Parent = ConfigFrame
Instance.new("UICorner", cfgIsland).CornerRadius = UDim.new(1, 0)

local cfgTitle = Instance.new("TextLabel")
cfgTitle.Size = UDim2.new(1, 0, 0, 35)
cfgTitle.Position = UDim2.new(0, 0, 0, 55)
cfgTitle.BackgroundTransparency = 1
cfgTitle.Text = "âš™ï¸ ConfiguraÃ§Ãµes"
cfgTitle.TextColor3 = Color3.new(1,1,1)
cfgTitle.Font = Enum.Font.GothamBold
cfgTitle.TextSize = 20
cfgTitle.Parent = ConfigFrame

local cfgScroll = Instance.new("ScrollingFrame")
cfgScroll.Size = UDim2.new(1, -24, 1, -110)
cfgScroll.Position = UDim2.new(0, 12, 0, 100)
cfgScroll.BackgroundTransparency = 1
cfgScroll.ScrollBarThickness = 4
cfgScroll.Parent = ConfigFrame

local cfgLayout = Instance.new("UIListLayout")
cfgLayout.Padding = UDim.new(0, 12)
cfgLayout.Parent = cfgScroll

local function createConfigToggle(title, desc, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 72)
    frame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    frame.Parent = cfgScroll
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

    local titleL = Instance.new("TextLabel")
    titleL.Size = UDim2.new(1, -70, 0, 25)
    titleL.Position = UDim2.new(0, 14, 0, 10)
    titleL.BackgroundTransparency = 1
    titleL.Text = title
    titleL.TextColor3 = Color3.new(1,1,1)
    titleL.Font = Enum.Font.GothamBold
    titleL.TextSize = 14
    titleL.TextXAlignment = Enum.TextXAlignment.Left
    titleL.Parent = frame

    local descL = Instance.new("TextLabel")
    descL.Size = UDim2.new(1, -70, 0, 30)
    descL.Position = UDim2.new(0, 14, 0, 34)
    descL.BackgroundTransparency = 1
    descL.Text = desc
    descL.TextColor3 = Color3.fromRGB(160, 160, 170)
    descL.Font = Enum.Font.Gotham
    descL.TextSize = 11
    descL.TextXAlignment = Enum.TextXAlignment.Left
    descL.TextWrapped = true
    descL.Parent = frame

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 52, 0, 30)
    toggle.Position = UDim2.new(1, -64, 0.5, -15)
    toggle.BackgroundColor3 = default and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(55, 55, 62)
    toggle.Text = default and "ON" or "OFF"
    toggle.TextColor3 = Color3.new(1,1,1)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 12
    toggle.Parent = frame
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 15)

    local state = default
    toggle.MouseButton1Click:Connect(function()
        playHaptic(0.3)
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(55, 55, 62)
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
serverInfoFrame.Size = UDim2.new(1, 0, 0, 120)
serverInfoFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
serverInfoFrame.Parent = cfgScroll
Instance.new("UICorner", serverInfoFrame).CornerRadius = UDim.new(0, 16)

local serverTitle = Instance.new("TextLabel")
serverTitle.Size = UDim2.new(1, -20, 0, 25)
serverTitle.Position = UDim2.new(0, 14, 0, 10)
serverTitle.BackgroundTransparency = 1
serverTitle.Text = "ðŸ“¡ Info do Servidor"
serverTitle.TextColor3 = Color3.new(1,1,1)
serverTitle.Font = Enum.Font.GothamBold
serverTitle.TextSize = 14
serverTitle.TextXAlignment = Enum.TextXAlignment.Left
serverTitle.Parent = serverInfoFrame

local serverInfoLabel = Instance.new("TextLabel")
serverInfoLabel.Size = UDim2.new(1, -28, 0, 75)
serverInfoLabel.Position = UDim2.new(0, 14, 0, 38)
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

        local serverType = (game.JobId ~= "" and game.PrivateServerId ~= "") and "Privado" or "PÃºblico"

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
GalleryFrame.Size = UDim2.new(0, 290, 0, 560)
GalleryFrame.Position = UDim2.new(1, -310, 0.5, -280)
GalleryFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
GalleryFrame.BorderSizePixel = 0
GalleryFrame.Visible = false
GalleryFrame.Active = true
GalleryFrame.Draggable = true
GalleryFrame.Parent = ScreenGui

Instance.new("UICorner", GalleryFrame).CornerRadius = UDim.new(0, 42)

local galBezel = Instance.new("UIStroke")
galBezel.Color = Color3.fromRGB(45, 45, 55)
galBezel.Thickness = 5
galBezel.Parent = GalleryFrame

local galIsland = Instance.new("Frame")
galIsland.Name = "DynamicIsland"
galIsland.Size = UDim2.new(0, 118, 0, 32)
galIsland.Position = UDim2.new(0.5, -59, 0, 14)
galIsland.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
galIsland.BorderSizePixel = 0
galIsland.ZIndex = 15
galIsland.Parent = GalleryFrame
Instance.new("UICorner", galIsland).CornerRadius = UDim.new(1, 0)

local galTitle = Instance.new("TextLabel")
galTitle.Size = UDim2.new(1, 0, 0, 30)
galTitle.Position = UDim2.new(0, 0, 0, 55)
galTitle.BackgroundTransparency = 1
galTitle.Text = "ðŸ–¼ï¸ Galeria"
galTitle.TextColor3 = Color3.new(1, 1, 1)
galTitle.Font = Enum.Font.GothamBold
galTitle.TextSize = 20
galTitle.Parent = GalleryFrame

local PhotoSearchBox = Instance.new("TextBox")
PhotoSearchBox.Size = UDim2.new(1, -28, 0, 34)
PhotoSearchBox.Position = UDim2.new(0, 14, 0, 95)
PhotoSearchBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
PhotoSearchBox.PlaceholderText = "ðŸ” Pesquisar foto..."
PhotoSearchBox.Text = ""
PhotoSearchBox.TextColor3 = Color3.new(1, 1, 1)
PhotoSearchBox.Font = Enum.Font.Gotham
PhotoSearchBox.TextSize = 13
PhotoSearchBox.Parent = GalleryFrame
Instance.new("UICorner", PhotoSearchBox).CornerRadius = UDim.new(0, 12)
local photoSearchStroke = Instance.new("UIStroke")
photoSearchStroke.Color = Color3.fromRGB(50, 50, 60)
photoSearchStroke.Thickness = 1
photoSearchStroke.Parent = PhotoSearchBox

local PhotoScrollList = Instance.new("ScrollingFrame")
PhotoScrollList.Size = UDim2.new(1, -28, 0, 340)
PhotoScrollList.Position = UDim2.new(0, 14, 0, 140)
PhotoScrollList.BackgroundTransparency = 1
PhotoScrollList.ScrollBarThickness = 3
PhotoScrollList.ScrollBarImageColor3 = Color3.fromRGB(50, 205, 50)
PhotoScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
PhotoScrollList.Parent = GalleryFrame

local PhotoUIGridLayout = Instance.new("UIGridLayout")
PhotoUIGridLayout.CellSize = UDim2.new(0, 62, 0, 62)
PhotoUIGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
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
Instance.new("UICorner", PhotoViewerView).CornerRadius = UDim.new(0, 42)

local PhotoDisplay = Instance.new("ImageLabel")
PhotoDisplay.Name = "PhotoDisplay"
PhotoDisplay.Size = UDim2.new(1, -20, 1, -130)
PhotoDisplay.Position = UDim2.new(0, 10, 0, 50)
PhotoDisplay.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
PhotoDisplay.BackgroundTransparency = 0.3
PhotoDisplay.BorderSizePixel = 0
PhotoDisplay.ScaleType = Enum.ScaleType.Fit
PhotoDisplay.Parent = PhotoViewerView
Instance.new("UICorner", PhotoDisplay).CornerRadius = UDim.new(0, 16)

local PhotoNameLabel = Instance.new("TextLabel")
PhotoNameLabel.Size = UDim2.new(1, -20, 0, 24)
PhotoNameLabel.Position = UDim2.new(0, 10, 1, -105)
PhotoNameLabel.BackgroundTransparency = 1
PhotoNameLabel.Text = ""
PhotoNameLabel.TextColor3 = Color3.new(1, 1, 1)
PhotoNameLabel.Font = Enum.Font.GothamBold
PhotoNameLabel.TextSize = 14
PhotoNameLabel.TextXAlignment = Enum.TextXAlignment.Center
PhotoNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
PhotoNameLabel.Parent = PhotoViewerView

-- BotÃµes de navegaÃ§Ã£o da galeria (anterior / prÃ³xima)
local prevPhotoBtn = Instance.new("TextButton")
prevPhotoBtn.Name = "PrevPhoto"
prevPhotoBtn.Size = UDim2.new(0, 80, 0, 38)
prevPhotoBtn.Position = UDim2.new(0, 24, 1, -60)
prevPhotoBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
prevPhotoBtn.Text = "â—€ Anterior"
prevPhotoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prevPhotoBtn.Font = Enum.Font.GothamBold
prevPhotoBtn.TextSize = 13
prevPhotoBtn.Parent = PhotoViewerView
Instance.new("UICorner", prevPhotoBtn).CornerRadius = UDim.new(0, 12)

local nextPhotoBtn = Instance.new("TextButton")
nextPhotoBtn.Name = "NextPhoto"
nextPhotoBtn.Size = UDim2.new(0, 80, 0, 38)
nextPhotoBtn.Position = UDim2.new(1, -104, 1, -60)
nextPhotoBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
nextPhotoBtn.Text = "PrÃ³xima â–¶"
nextPhotoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
nextPhotoBtn.Font = Enum.Font.GothamBold
nextPhotoBtn.TextSize = 13
nextPhotoBtn.Parent = PhotoViewerView
Instance.new("UICorner", nextPhotoBtn).CornerRadius = UDim.new(0, 12)

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
    playHaptic(0.25)
    if #filteredPhotoList > 0 then
        openPhotoByIndex(currentPhotoIndex - 1)
    end
end)

nextPhotoBtn.MouseButton1Click:Connect(function()
    playHaptic(0.25)
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
        Instance.new("UICorner", emptyFrame).CornerRadius = UDim.new(0, 12)

        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 1, 0)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = searchText == "" and "ðŸ“ Coloque fotos em PHONE/Photos" or "ðŸ” Nenhuma foto encontrada"
        emptyLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
        emptyLabel.TextSize = 12
        emptyLabel.Parent = emptyFrame
    else
        for idx, photo in ipairs(filteredPhotoList) do
            local thumbBtn = Instance.new("ImageButton")
            thumbBtn.Size = UDim2.new(0, 62, 0, 62)
            thumbBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            thumbBtn.BorderSizePixel = 0
            thumbBtn.ScaleType = Enum.ScaleType.Crop
            thumbBtn.AutoButtonColor = false
            thumbBtn.Parent = PhotoScrollList
            Instance.new("UICorner", thumbBtn).CornerRadius = UDim.new(0, 12)

            pcall(function()
                local asset = getcustomasset(photo.path)
                if asset then
                    thumbBtn.Image = asset
                end
            end)

            thumbBtn.MouseButton1Click:Connect(function()
                playHaptic(0.25)
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

-- ========== NAVEGAÃ‡ÃƒO ==========
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

    local target = UDim2.new(1, -310, 1, 120)
    local frames = {PhoneHome, MainFrame, StopwatchFrame, ConfigFrame, GalleryFrame}
    for _, f in ipairs(frames) do
        if f.Visible then
            local tween = TweenService:Create(f, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = target})
            tween:Play()
            tween.Completed:Once(function()
                f.Visible = false
            end)
        end
    end

    disablePhoneBlur()

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
    PhoneHome.Position = UDim2.new(1, -310, 1, 120)
    PhoneHome.Visible = true
    local target = UDim2.new(1, -310, 0.5, -280)
    local tween = TweenService:Create(PhoneHome, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = target})
    tween:Play()
    enablePhoneBlur()
    attachVolumeTo(PhoneHome)
    updateMovementStats()
    playHaptic(0.4)
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
    playHaptic(0.25)
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
        PlayBtn.Text = "â¸"
    else
        currentSound:Pause()
        PlayBtn.Text = "â–¶"
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
    ShuffleBtn.Text = shuffleMode and "ðŸ”€" or "âž¡ï¸"
    ShuffleBtn.BackgroundColor3 = shuffleMode and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(28, 28, 34)
end)

RepeatBtn.MouseButton1Click:Connect(function()
    repeatMode = not repeatMode
    RepeatBtn.Text = repeatMode and "ðŸ”" or "ðŸ”‚"
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
-- CHARACTER HANDLING (sem criaÃ§Ã£o de Tools)
-- =========================================================
local function onCharacterAdded(char)
    cleanup()
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    
    originalWalkSpeed = Humanoid.WalkSpeed
    phoneSettings.joinTime = os.clock()

    removeExtraRoots()

    Humanoid.JumpPower = SETTINGS.JumpPower
end

Player.CharacterRemoving:Connect(cleanup)
Player.CharacterAdded:Connect(onCharacterAdded)
if Player.Character then onCharacterAdded(Player.Character) end
