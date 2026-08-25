-- =========================================================
-- MENU DE SELEÇÃO INICIAL (apenas Phone)
-- =========================================================
local selectedItems = {
    TzesPhone   = false
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
    Main.Size = UDim2.new(0, 210, 0, 120)
    Main.Position = UDim2.new(0.5, -105, 0.5, -60)
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
        {Key = "TzesPhone",   Emoji = "📱", Name = "Phone"}
    }

    local toggleButtons = {}

    for i, data in ipairs(items) do
        local btn = Instance.new("TextButton")
        btn.Name = data.Key
        btn.Size = UDim2.new(0, 190, 0, 32)
        btn.Position = UDim2.new(0, 10, 0, 36)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        btn.Text = data.Emoji .. " " .. data.Name
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
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

    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Size = UDim2.new(0, 190, 0, 28)
    confirmBtn.Position = UDim2.new(0, 10, 0, 78)
    confirmBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
    confirmBtn.Text = "Confirmar"
    confirmBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.TextSize = 13
    confirmBtn.AutoButtonColor = false
    confirmBtn.Parent = Main
    Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 7)

    confirmBtn.MouseButton1Click:Connect(function()
        for key, info in pairs(toggleButtons) do
            selectedItems[key] = info.selected
        end
        -- Sempre força o Phone se não selecionou nada (script agora só tem Phone)
        if not selectedItems.TzesPhone then
            selectedItems.TzesPhone = true
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
-- SISTEMA DE CONFIGURAÇÕES PERSISTENTES (JSON)
-- =========================================================
local CONFIG_PATH = "PHONE/phone_config.json"

local phoneSettings = {
    fpsEnabled = false,
    flashlightEnabled = false,
    joinTime = os.clock(),
    volume = 1,
    wallpaper = "rbxassetid://12506271392", -- padrão
    phoneButtonPos = nil -- {xScale, xOffset, yScale, yOffset}
}

local function saveConfig()
    pcall(function()
        local data = {
            fpsEnabled = phoneSettings.fpsEnabled,
            flashlightEnabled = phoneSettings.flashlightEnabled,
            volume = phoneSettings.volume,
            wallpaper = phoneSettings.wallpaper,
            phoneButtonPos = phoneSettings.phoneButtonPos
        }
        writefile(CONFIG_PATH, game:GetService("HttpService"):JSONEncode(data))
    end)
end

local function loadConfig()
    pcall(function()
        if isfile(CONFIG_PATH) then
            local raw = readfile(CONFIG_PATH)
            local data = game:GetService("HttpService"):JSONDecode(raw)
            if type(data) == "table" then
                if data.fpsEnabled ~= nil then phoneSettings.fpsEnabled = data.fpsEnabled end
                if data.flashlightEnabled ~= nil then phoneSettings.flashlightEnabled = data.flashlightEnabled end
                if data.volume ~= nil then phoneSettings.volume = data.volume end
                if data.wallpaper and data.wallpaper ~= "" then phoneSettings.wallpaper = data.wallpaper end
                if data.phoneButtonPos then phoneSettings.phoneButtonPos = data.phoneButtonPos end
            end
        end
    end)
end

loadConfig()

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
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CaptureService = game:GetService("CaptureService")

local isTouchDevice = UserInputService.TouchEnabled

local SOUNDS = {}

local fpsLabel = nil
local phoneFlashlight = nil

-- Estados de "equipamento" via hotbar (sem Tools)
local equippedItem = nil          -- "TzesPhone" | nil

local function createSounds()
    -- sem sons de cola
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
-- CUSTOM HOTBAR (só o Phone) - SEM TOOLS
-- =========================================================
local HotbarGui = Instance.new("ScreenGui")
HotbarGui.Name = "TzeCustomHotbar"
HotbarGui.ResetOnSpawn = false
HotbarGui.IgnoreGuiInset = true
HotbarGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HotbarGui.Parent = game:GetService("CoreGui")

local HotbarFrame = Instance.new("Frame")
HotbarFrame.Name = "HotbarFrame"
HotbarFrame.Size = UDim2.new(0, 48, 0, 48)
HotbarFrame.Position = UDim2.new(1, -60, 1, -80)
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
        -- Já está equipado → desequipa
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
    slot.Size = UDim2.new(0, 40, 0, 40)
    slot.Position = UDim2.new(0, 4, 0, 4)
    slot.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    slot.BorderSizePixel = 0
    slot.Text = ""
    slot.AutoButtonColor = false
    slot.Parent = HotbarFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
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
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 12)

    local emoji = Instance.new("TextLabel")
    emoji.Size = UDim2.new(1, 0, 1, 0)
    emoji.BackgroundTransparency = 1
    emoji.Text = data.Emoji
    emoji.TextSize = 22
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
    Instance.new("UICorner", selected).CornerRadius = UDim.new(0, 12)

    -- Sistema de arrastar o botão do phone (segurar 0.45s)
    local isDragging = false
    local dragStartTime = 0
    local dragConnection = nil
    local holdConnection = nil
    local originalPos = slot.Position
    local dragOffset = Vector2.new(0, 0)

    local function startDrag(input)
        if isDragging then return end
        isDragging = true
        slot.ZIndex = 50
        -- Animação de "pegar"
        TweenService:Create(slot, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 48, 0, 48),
            BackgroundColor3 = Color3.fromRGB(50, 205, 50)
        }):Play()
        local strokeTween = TweenService:Create(stroke, TweenInfo.new(0.15), {Thickness = 3.5})
        strokeTween:Play()

        local startPos = input.Position
        dragOffset = Vector2.new(slot.AbsolutePosition.X - startPos.X, slot.AbsolutePosition.Y - startPos.Y)

        dragConnection = UserInputService.InputChanged:Connect(function(inp)
            if not isDragging then return end
            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                local newX = inp.Position.X + dragOffset.X
                local newY = inp.Position.Y + dragOffset.Y
                local cam = Workspace.CurrentCamera
                if cam then
                    local vs = cam.ViewportSize
                    newX = math.clamp(newX, 0, vs.X - slot.AbsoluteSize.X)
                    newY = math.clamp(newY, 0, vs.Y - slot.AbsoluteSize.Y)
                end
                -- Converte para posição relativa ao HotbarFrame parent (que é full screen via Absolute)
                -- Como HotbarFrame está posicionado, movemos o próprio HotbarFrame
                HotbarFrame.Position = UDim2.new(0, newX, 0, newY)
            end
        end)
    end

    local function stopDrag()
        if not isDragging then return end
        isDragging = false
        if dragConnection then
            dragConnection:Disconnect()
            dragConnection = nil
        end
        slot.ZIndex = 1
        TweenService:Create(slot, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 40, 0, 40),
            BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Thickness = 2.5}):Play()

        -- Salva posição
        local absPos = HotbarFrame.AbsolutePosition
        local cam = Workspace.CurrentCamera
        if cam then
            local vs = cam.ViewportSize
            phoneSettings.phoneButtonPos = {
                xScale = 0,
                xOffset = absPos.X,
                yScale = 0,
                yOffset = absPos.Y
            }
            saveConfig()
        end
    end

    slot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStartTime = os.clock()
            holdConnection = task.delay(0.45, function()
                if holdConnection then
                    startDrag(input)
                end
            end)
        end
    end)

    slot.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if holdConnection then
                task.cancel(holdConnection)
                holdConnection = nil
            end
            if isDragging then
                stopDrag()
            else
                -- Clique normal (menos de 0.45s)
                if os.clock() - dragStartTime < 0.45 then
                    equipItem(data.ToolName)
                end
            end
        end
    end)

    -- Também para mouse leave em PC
    slot.MouseLeave:Connect(function()
        if isDragging then
            stopDrag()
        end
    end)

    slotButtons[data.ToolName] = {button = slot, selected = selected, data = data}
    return slot
end

for i, data in ipairs(activeSlots) do
    createSlot(i, data)
end

if #activeSlots > 0 then
    HotbarFrame.Size = UDim2.new(0, 48, 0, 48)
    -- Restaura posição salva se existir
    if phoneSettings.phoneButtonPos then
        local p = phoneSettings.phoneButtonPos
        HotbarFrame.Position = UDim2.new(p.xScale or 0, p.xOffset or 0, p.yScale or 0, p.yOffset or 0)
    else
        HotbarFrame.Position = UDim2.new(1, -60, 1, -80)
    end
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

local currentSound = nil
local isPaused = false
local currentMode = "File"
local mp3List = {}
local filteredList = {}
local currentTrackIndex = 0
local shuffleMode = false
local repeatMode = false
local currentVolume = phoneSettings.volume or 1
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

-- ========== PHONE HOME SCREEN (FIXO - não arrastável) ==========
local PhoneHome = Instance.new("Frame")
PhoneHome.Name = "PhoneHome"
PhoneHome.Size = UDim2.new(0, 280, 0, 440)
PhoneHome.Position = UDim2.new(1, -300, 0.5, -220)
PhoneHome.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
PhoneHome.BorderSizePixel = 0
PhoneHome.Visible = false
PhoneHome.Active = true
PhoneHome.Draggable = false -- FIXO
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
homeBg.Image = phoneSettings.wallpaper or "rbxassetid://12506271392"
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
fpsLabel.Visible = phoneSettings.fpsEnabled
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
local CameraAppIcon = createAppIcon("Câmera", "📷", Color3.fromRGB(255, 80, 80), UDim2.new(0, 85, 0, 100))

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
VolumeFrame.Size = UDim2.new(0, 16, 0, 96)
VolumeFrame.Position = UDim2.new(0, -22, 0.5, -130)
VolumeFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
VolumeFrame.BackgroundTransparency = 0.15
VolumeFrame.BorderSizePixel = 0
VolumeFrame.ZIndex = 30
VolumeFrame.Visible = false
VolumeFrame.Parent = ScreenGui
Instance.new("UICorner", VolumeFrame).CornerRadius = UDim.new(0, 8)
local volFrameStroke = Instance.new("UIStroke")
volFrameStroke.Color = Color3.fromRGB(50, 205, 50)
volFrameStroke.Thickness = 1.2
volFrameStroke.Parent = VolumeFrame

local VolUpBtn = Instance.new("TextButton")
VolUpBtn.Name = "VolUp"
VolUpBtn.Size = UDim2.new(1, -4, 0, 42)
VolUpBtn.Position = UDim2.new(0, 2, 0, 3)
VolUpBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
VolUpBtn.Text = "🔊"
VolUpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VolUpBtn.Font = Enum.Font.GothamBold
VolUpBtn.TextSize = 13
VolUpBtn.ZIndex = 31
VolUpBtn.Parent = VolumeFrame
Instance.new("UICorner", VolUpBtn).CornerRadius = UDim.new(0, 6)
local volUpStroke = Instance.new("UIStroke")
volUpStroke.Color = Color3.fromRGB(50, 205, 50)
volUpStroke.Thickness = 1
volUpStroke.Parent = VolUpBtn

local VolDownBtn = Instance.new("TextButton")
VolDownBtn.Name = "VolDown"
VolDownBtn.Size = UDim2.new(1, -4, 0, 42)
VolDownBtn.Position = UDim2.new(0, 2, 0, 51)
VolDownBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
VolDownBtn.Text = "🔉"
VolDownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VolDownBtn.Font = Enum.Font.GothamBold
VolDownBtn.TextSize = 13
VolDownBtn.ZIndex = 31
VolDownBtn.Parent = VolumeFrame
Instance.new("UICorner", VolDownBtn).CornerRadius = UDim.new(0, 6)
local volDownStroke = Instance.new("UIStroke")
volDownStroke.Color = Color3.fromRGB(50, 205, 50)
volDownStroke.Thickness = 1
volDownStroke.Parent = VolDownBtn

VolUpBtn.MouseButton1Click:Connect(function()
    currentVolume = math.clamp(currentVolume + 0.1, 0, 1)
    phoneSettings.volume = currentVolume
    saveConfig()
    if currentSound then
        currentSound.Volume = currentVolume
    end
end)

VolDownBtn.MouseButton1Click:Connect(function()
    currentVolume = math.clamp(currentVolume - 0.1, 0, 1)
    phoneSettings.volume = currentVolume
    saveConfig()
    if currentSound then
        currentSound.Volume = currentVolume
    end
end)

local function attachVolumeTo(frame)
    if not frame then return end
    VolumeFrame.Parent = frame
    VolumeFrame.Position = UDim2.new(0, -22, 0.5, -130)
    VolumeFrame.BackgroundTransparency = 0.15
    VolumeFrame.Visible = true
end

-- ========== MUSIC PLAYER (FIXO) ==========
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 440)
MainFrame.Position = UDim2.new(1, -300, 0.5, -220)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = false -- FIXO
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

-- ========== CRONÔMETRO (FIXO) ==========
local StopwatchFrame = Instance.new("Frame")
StopwatchFrame.Name = "StopwatchFrame"
StopwatchFrame.Size = UDim2.new(0, 280, 0, 440)
StopwatchFrame.Position = UDim2.new(1, -300, 0.5, -220)
StopwatchFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
StopwatchFrame.BorderSizePixel = 0
StopwatchFrame.Visible = false
StopwatchFrame.Active = true
StopwatchFrame.Draggable = false -- FIXO
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

-- ========== CONFIG APP (FIXO) ==========
local ConfigFrame = Instance.new("Frame")
ConfigFrame.Name = "ConfigFrame"
ConfigFrame.Size = UDim2.new(0, 280, 0, 440)
ConfigFrame.Position = UDim2.new(1, -300, 0.5, -220)
ConfigFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
ConfigFrame.BorderSizePixel = 0
ConfigFrame.Visible = false
ConfigFrame.Active = true
ConfigFrame.Draggable = false -- FIXO
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
        saveConfig()
    end)

    return frame
end

createConfigToggle("FPS Counter", "Mostra o FPS na tela inicial do celular", phoneSettings.fpsEnabled, function(on)
    phoneSettings.fpsEnabled = on
    if fpsLabel then
        fpsLabel.Visible = on
    end
end)

createConfigToggle("Lanterna do Celular", "Liga uma luz fraca na frente do personagem", phoneSettings.flashlightEnabled, function(on)
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

-- Wallpaper custom
local wallpaperFrame = Instance.new("Frame")
wallpaperFrame.Size = UDim2.new(1, 0, 0, 140)
wallpaperFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
wallpaperFrame.Parent = cfgScroll
Instance.new("UICorner", wallpaperFrame).CornerRadius = UDim.new(0, 12)

local wpTitle = Instance.new("TextLabel")
wpTitle.Size = UDim2.new(1, -20, 0, 25)
wpTitle.Position = UDim2.new(0, 12, 0, 8)
wpTitle.BackgroundTransparency = 1
wpTitle.Text = "🖼️ Wallpaper"
wpTitle.TextColor3 = Color3.new(1,1,1)
wpTitle.Font = Enum.Font.GothamBold
wpTitle.TextSize = 14
wpTitle.TextXAlignment = Enum.TextXAlignment.Left
wpTitle.Parent = wallpaperFrame

local wpInput = Instance.new("TextBox")
wpInput.Size = UDim2.new(1, -24, 0, 32)
wpInput.Position = UDim2.new(0, 12, 0, 40)
wpInput.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
wpInput.PlaceholderText = "rbxassetid:// ou nome da foto"
wpInput.Text = ""
wpInput.TextColor3 = Color3.new(1,1,1)
wpInput.Font = Enum.Font.Gotham
wpInput.TextSize = 12
wpInput.Parent = wallpaperFrame
Instance.new("UICorner", wpInput).CornerRadius = UDim.new(0, 8)

local wpApplyBtn = Instance.new("TextButton")
wpApplyBtn.Size = UDim2.new(0, 100, 0, 30)
wpApplyBtn.Position = UDim2.new(0, 12, 0, 82)
wpApplyBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
wpApplyBtn.Text = "Aplicar ID"
wpApplyBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
wpApplyBtn.Font = Enum.Font.GothamBold
wpApplyBtn.TextSize = 12
wpApplyBtn.Parent = wallpaperFrame
Instance.new("UICorner", wpApplyBtn).CornerRadius = UDim.new(0, 8)

local wpFromGalleryBtn = Instance.new("TextButton")
wpFromGalleryBtn.Size = UDim2.new(0, 120, 0, 30)
wpFromGalleryBtn.Position = UDim2.new(0, 120, 0, 82)
wpFromGalleryBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
wpFromGalleryBtn.Text = "Da Galeria"
wpFromGalleryBtn.TextColor3 = Color3.new(1,1,1)
wpFromGalleryBtn.Font = Enum.Font.GothamBold
wpFromGalleryBtn.TextSize = 12
wpFromGalleryBtn.Parent = wallpaperFrame
Instance.new("UICorner", wpFromGalleryBtn).CornerRadius = UDim.new(0, 8)

local function applyWallpaper(img)
    if not img or img == "" then return end
    phoneSettings.wallpaper = img
    homeBg.Image = img
    saveConfig()
end

wpApplyBtn.MouseButton1Click:Connect(function()
    local txt = wpInput.Text:gsub("%s+", "")
    if txt == "" then return end
    if not txt:find("rbxassetid://") and not txt:find("http") then
        -- tenta como ID numérico
        if tonumber(txt) then
            txt = "rbxassetid://" .. txt
        end
    end
    applyWallpaper(txt)
    wpInput.Text = ""
end)

-- Galeria picker para wallpaper (abre lista simples)
local wpGalleryPicker = Instance.new("Frame")
wpGalleryPicker.Size = UDim2.new(1, -24, 0, 180)
wpGalleryPicker.Position = UDim2.new(0, 12, 0, 120)
wpGalleryPicker.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
wpGalleryPicker.Visible = false
wpGalleryPicker.Parent = wallpaperFrame
Instance.new("UICorner", wpGalleryPicker).CornerRadius = UDim.new(0, 10)

local wpGalScroll = Instance.new("ScrollingFrame")
wpGalScroll.Size = UDim2.new(1, -10, 1, -10)
wpGalScroll.Position = UDim2.new(0, 5, 0, 5)
wpGalScroll.BackgroundTransparency = 1
wpGalScroll.ScrollBarThickness = 3
wpGalScroll.Parent = wpGalleryPicker

local wpGalLayout = Instance.new("UIListLayout")
wpGalLayout.Padding = UDim.new(0, 4)
wpGalLayout.Parent = wpGalScroll

wpFromGalleryBtn.MouseButton1Click:Connect(function()
    wpGalleryPicker.Visible = not wpGalleryPicker.Visible
    if wpGalleryPicker.Visible then
        -- limpa e popula
        for _, c in pairs(wpGalScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        -- usa photoList se disponível
        pcall(function()
            local paths = {"PHONE/Photos/", "PHONE/Photos"}
            local files
            for _, p in ipairs(paths) do
                local ok, f = pcall(listfiles, p)
                if ok and type(f) == "table" and #f > 0 then
                    files = f
                    break
                end
            end
            if files then
                for _, file in ipairs(files) do
                    local str = tostring(file)
                    local lower = str:lower()
                    if lower:match("%.png$") or lower:match("%.jpg$") or lower:match("%.jpeg$") or lower:match("%.webp$") then
                        local name = str:match("([^/\\]+)$") or str
                        local btn = Instance.new("TextButton")
                        btn.Size = UDim2.new(1, 0, 0, 28)
                        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
                        btn.Text = "  " .. name
                        btn.TextColor3 = Color3.new(1,1,1)
                        btn.TextXAlignment = Enum.TextXAlignment.Left
                        btn.TextSize = 11
                        btn.Font = Enum.Font.Gotham
                        btn.Parent = wpGalScroll
                        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                        btn.MouseButton1Click:Connect(function()
                            local ok, asset = pcall(getcustomasset, file)
                            if ok and asset then
                                applyWallpaper(asset)
                                wpGalleryPicker.Visible = false
                            end
                        end)
                    end
                end
                wpGalScroll.CanvasSize = UDim2.new(0, 0, 0, wpGalLayout.AbsoluteContentSize.Y + 10)
            end
        end)
        -- aumenta altura do frame de wallpaper
        wallpaperFrame.Size = UDim2.new(1, 0, 0, 320)
    else
        wallpaperFrame.Size = UDim2.new(1, 0, 0, 140)
    end
    cfgScroll.CanvasSize = UDim2.new(0, 0, 0, cfgLayout.AbsoluteContentSize.Y + 20)
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

-- ========== GALERIA APP (FIXO) ==========
local GalleryFrame = Instance.new("Frame")
GalleryFrame.Name = "GalleryFrame"
GalleryFrame.Size = UDim2.new(0, 280, 0, 440)
GalleryFrame.Position = UDim2.new(1, -300, 0.5, -220)
GalleryFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
GalleryFrame.BorderSizePixel = 0
GalleryFrame.Visible = false
GalleryFrame.Active = true
GalleryFrame.Draggable = false -- FIXO
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

-- Zoom com pinça (mobile) + scroll (PC)
local currentZoom = 1
local minZoom = 1
local maxZoom = 4
local pinchStartDist = 0
local pinchStartZoom = 1
local activeTouches = {}

local function updateZoom()
    PhotoDisplay.Size = UDim2.new(currentZoom, -16 * currentZoom, currentZoom, -110 * currentZoom)
    PhotoDisplay.Position = UDim2.new(0.5 - currentZoom/2, 8 * currentZoom, 0.5 - currentZoom/2 + 0.05, 40)
end

UserInputService.TouchStarted:Connect(function(touch, processed)
    if not isInPhotoViewer then return end
    activeTouches[touch] = touch.Position
    if #activeTouches >= 2 then
        local positions = {}
        for _, pos in pairs(activeTouches) do
            table.insert(positions, pos)
        end
        if #positions >= 2 then
            pinchStartDist = (positions[1] - positions[2]).Magnitude
            pinchStartZoom = currentZoom
        end
    end
end)

UserInputService.TouchMoved:Connect(function(touch, processed)
    if not isInPhotoViewer then return end
    activeTouches[touch] = touch.Position
    local positions = {}
    for _, pos in pairs(activeTouches) do
        table.insert(positions, pos)
    end
    if #positions >= 2 and pinchStartDist > 0 then
        local dist = (positions[1] - positions[2]).Magnitude
        local scale = dist / pinchStartDist
        currentZoom = math.clamp(pinchStartZoom * scale, minZoom, maxZoom)
        updateZoom()
    end
end)

UserInputService.TouchEnded:Connect(function(touch, processed)
    activeTouches[touch] = nil
    if #activeTouches < 2 then
        pinchStartDist = 0
    end
end)

-- Zoom com scroll do mouse (PC)
UserInputService.InputChanged:Connect(function(input)
    if not isInPhotoViewer then return end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        local delta = input.Position.Z
        currentZoom = math.clamp(currentZoom + delta * 0.15, minZoom, maxZoom)
        updateZoom()
    end
end)

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

-- Botão de excluir foto
local deletePhotoBtn = Instance.new("TextButton")
deletePhotoBtn.Name = "DeletePhoto"
deletePhotoBtn.Size = UDim2.new(0, 70, 0, 36)
deletePhotoBtn.Position = UDim2.new(0.5, -35, 1, -55)
deletePhotoBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
deletePhotoBtn.Text = "🗑️ Excluir"
deletePhotoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deletePhotoBtn.Font = Enum.Font.GothamBold
deletePhotoBtn.TextSize = 12
deletePhotoBtn.Parent = PhotoViewerView
Instance.new("UICorner", deletePhotoBtn).CornerRadius = UDim.new(0, 10)

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
    currentZoom = 1
    updateZoom()
end

local function openPhotoByIndex(idx)
    if #filteredPhotoList == 0 then return end
    if idx < 1 then idx = #filteredPhotoList end
    if idx > #filteredPhotoList then idx = 1 end
    currentPhotoIndex = idx
    currentZoom = 1
    updateZoom()

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

deletePhotoBtn.MouseButton1Click:Connect(function()
    if #filteredPhotoList == 0 or currentPhotoIndex < 1 then return end
    local photo = filteredPhotoList[currentPhotoIndex]
    if not photo then return end

    -- Confirma visualmente
    deletePhotoBtn.Text = "..."
    local ok = pcall(function()
        if isfile(photo.path) then
            delfile(photo.path)
        end
    end)
    if ok then
        -- remove da lista
        for i, p in ipairs(photoList) do
            if p.path == photo.path then
                table.remove(photoList, i)
                break
            end
        end
        for i, p in ipairs(filteredPhotoList) do
            if p.path == photo.path then
                table.remove(filteredPhotoList, i)
                break
            end
        end
        if #filteredPhotoList == 0 then
            exitPhotoViewer()
            updatePhotoList()
        else
            if currentPhotoIndex > #filteredPhotoList then
                currentPhotoIndex = #filteredPhotoList
            end
            openPhotoByIndex(currentPhotoIndex)
            updatePhotoList()
        end
    end
    deletePhotoBtn.Text = "🗑️ Excluir"
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

-- ========== CÂMERA APP (NOVO) ==========
local CameraFrame = Instance.new("Frame")
CameraFrame.Name = "CameraFrame"
CameraFrame.Size = UDim2.new(0, 280, 0, 440)
CameraFrame.Position = UDim2.new(1, -300, 0.5, -220)
CameraFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
CameraFrame.BorderSizePixel = 0
CameraFrame.Visible = false
CameraFrame.Active = true
CameraFrame.Draggable = false -- FIXO
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
camEars.ZIndex = CameraFrame.ZIndex + 2
camEars.Parent = CameraFrame

local camNotch = Instance.new("Frame")
camNotch.Size = UDim2.new(0, 82, 0, 24)
camNotch.Position = UDim2.new(0.5, -41, 0, 9)
camNotch.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
camNotch.BorderSizePixel = 0
camNotch.Parent = CameraFrame
Instance.new("UICorner", camNotch).CornerRadius = UDim.new(1, 0)

local camTitle = Instance.new("TextLabel")
camTitle.Size = UDim2.new(1, 0, 0, 30)
camTitle.Position = UDim2.new(0, 0, 0, 45)
camTitle.BackgroundTransparency = 1
camTitle.Text = "📷 Câmera"
camTitle.TextColor3 = Color3.new(1, 1, 1)
camTitle.Font = Enum.Font.GothamBold
camTitle.TextSize = 20
camTitle.Parent = CameraFrame

local camPreview = Instance.new("Frame")
camPreview.Size = UDim2.new(1, -40, 0, 220)
camPreview.Position = UDim2.new(0, 20, 0, 90)
camPreview.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
camPreview.BorderSizePixel = 0
camPreview.Parent = CameraFrame
Instance.new("UICorner", camPreview).CornerRadius = UDim.new(0, 16)

local camPreviewLabel = Instance.new("TextLabel")
camPreviewLabel.Size = UDim2.new(1, 0, 1, 0)
camPreviewLabel.BackgroundTransparency = 1
camPreviewLabel.Text = "Aponte a câmera\ne tire a foto"
camPreviewLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
camPreviewLabel.Font = Enum.Font.Gotham
camPreviewLabel.TextSize = 16
camPreviewLabel.TextWrapped = true
camPreviewLabel.Parent = camPreview

local takePhotoBtn = Instance.new("TextButton")
takePhotoBtn.Size = UDim2.new(0, 80, 0, 80)
takePhotoBtn.Position = UDim2.new(0.5, -40, 0, 330)
takePhotoBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
takePhotoBtn.Text = ""
takePhotoBtn.Parent = CameraFrame
Instance.new("UICorner", takePhotoBtn).CornerRadius = UDim.new(1, 0)

local takePhotoInner = Instance.new("Frame")
takePhotoInner.Size = UDim2.new(0, 64, 0, 64)
takePhotoInner.Position = UDim2.new(0.5, -32, 0.5, -32)
takePhotoInner.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
takePhotoInner.BorderSizePixel = 0
takePhotoInner.Parent = takePhotoBtn
Instance.new("UICorner", takePhotoInner).CornerRadius = UDim.new(1, 0)

local camStatusLabel = Instance.new("TextLabel")
camStatusLabel.Size = UDim2.new(1, -20, 0, 24)
camStatusLabel.Position = UDim2.new(0, 10, 0, 300)
camStatusLabel.BackgroundTransparency = 1
camStatusLabel.Text = ""
camStatusLabel.TextColor3 = Color3.fromRGB(50, 205, 50)
camStatusLabel.Font = Enum.Font.Gotham
camStatusLabel.TextSize = 13
camStatusLabel.Parent = CameraFrame

local camNavBtn, camBackBtn = createNavBar(CameraFrame)

local isCapturing = false

takePhotoBtn.MouseButton1Click:Connect(function()
    if isCapturing then return end
    isCapturing = true
    camStatusLabel.Text = "Capturando..."
    takePhotoInner.BackgroundColor3 = Color3.fromRGB(180, 40, 40)

    -- Flash visual
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.new(1, 1, 1)
    flash.BackgroundTransparency = 0
    flash.BorderSizePixel = 0
    flash.ZIndex = 100
    flash.Parent = CameraFrame
    Instance.new("UICorner", flash).CornerRadius = UDim.new(0, 28)
    TweenService:Create(flash, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
    task.delay(0.4, function()
        if flash and flash.Parent then flash:Destroy() end
    end)

    task.spawn(function()
        local success = false
        local filename = "PHONE/Photos/foto_" .. os.date("%Y%m%d_%H%M%S") .. ".png"

        -- Tenta CaptureService se disponível
        local ok, err = pcall(function()
            if CaptureService and CaptureService.CaptureScreenshot then
                CaptureService:CaptureScreenshot(function(contentId)
                    -- contentId é um rbxassetid temporário; alguns executors permitem salvar
                    pcall(function()
                        -- Fallback: usa request se disponível para baixar, senão apenas notifica
                        if writefile then
                            -- Muitos executors não expõem o bytes do CaptureService diretamente.
                            -- Alternativa: salva um placeholder e usa getcustomasset depois se possível.
                            -- Aqui tentamos o método mais comum em executors:
                            if typeof(contentId) == "string" and contentId:find("rbxassetid") then
                                -- não temos bytes; apenas registra
                            end
                        end
                    end)
                end)
            end
        end)

        -- Método alternativo usado por muitos scripts de screenshot em exploit:
        -- Usa a API do executor se existir (alguns têm screenshot())
        pcall(function()
            if screenshot then
                local data = screenshot()
                if data and writefile then
                    writefile(filename, data)
                    success = true
                end
            end
        end)

        -- Outro fallback comum
        pcall(function()
            if syn and syn.request then
                -- não aplicável diretamente
            end
        end)

        -- Método genérico: alguns executors têm game:GetService("CoreGui") screenshot helpers
        -- Último recurso: cria um arquivo de marcação + tenta getcustomasset depois
        if not success then
            pcall(function()
                -- Tenta o método do Fluxus / Synapse / Wave / etc via request interno
                if request or http_request or (syn and syn.request) then
                    -- não gera bytes reais sem API
                end
                -- Cria um arquivo vazio apenas para indicar que tentou (melhor UX)
                -- Na prática a maioria dos executores modernos expõe uma função de screenshot
                if writefile and not isfile(filename) then
                    -- Não escreve lixo; apenas falha graciosamente
                end
            end)
        end

        -- Método mais confiável em 2025+ em vários executors: 
        -- Usar o CaptureService + esperar o contentId e depois usar um download se possível.
        -- Como fallback final usamos um aviso e salvamos timestamp.
        task.wait(0.6)

        if success then
            camStatusLabel.Text = "✅ Salva em PHONE/Photos"
            camStatusLabel.TextColor3 = Color3.fromRGB(50, 205, 50)
            refreshPhotos()
        else
            -- Tenta o método do Roblox CaptureService + writefile via content
            local finalOk = false
            pcall(function()
                if CaptureService then
                    CaptureService:CaptureScreenshot(function(content)
                        -- Em alguns ambientes content já é o asset utilizável
                        if content and writefile then
                            -- Não temos bytes crus; mas podemos registrar o asset
                            -- e a galeria pode tentar carregar depois se o executor permitir.
                            -- Alternativa prática: avisar o usuário e manter o fluxo.
                        end
                    end)
                end
            end)

            -- Fallback final mais usado em scripts de phone: 
            -- usa a função global se o executor injetar "screenshot" ou "takescreenshot"
            pcall(function()
                local funcs = {screenshot, takescreenshot, capture_screenshot, CaptureScreenshot}
                for _, fn in ipairs(funcs) do
                    if type(fn) == "function" then
                        local data = fn()
                        if type(data) == "string" and #data > 100 then
                            writefile(filename, data)
                            finalOk = true
                            break
                        end
                    end
                end
            end)

            if finalOk or isfile(filename) then
                camStatusLabel.Text = "✅ Salva em PHONE/Photos"
                camStatusLabel.TextColor3 = Color3.fromRGB(50, 205, 50)
                refreshPhotos()
            else
                camStatusLabel.Text = "⚠️ Screenshot não suportado neste executor"
                camStatusLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
            end
        end

        takePhotoInner.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        isCapturing = false
        task.delay(2.5, function()
            if camStatusLabel then
                camStatusLabel.Text = ""
            end
        end)
    end)
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
    attachVolumeTo(GalleryFrame)
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

    attachVolumeTo(CameraFrame)
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
ConfigAppIcon.MouseButton1Click:Connect(openConfigApp)
GalleryAppIcon.MouseButton1Click:Connect(openGalleryApp)
CameraAppIcon.MouseButton1Click:Connect(openCameraApp)

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

-- Tecla 0 no PC para abrir/fechar o phone
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Zero or input.KeyCode == Enum.KeyCode.KeypadZero then
        togglePhone()
    end
end)

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
        -- originalFOV não é mais usado ativamente
    end

    removeExtraRoots()
    createSounds()

    Humanoid.JumpPower = SETTINGS.JumpPower

    -- Restaura lanterna do celular se estava ligada
    if phoneSettings.flashlightEnabled then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            if phoneFlashlight then phoneFlashlight:Destroy() end
            phoneFlashlight = Instance.new("SpotLight")
            phoneFlashlight.Name = "PhoneFlashlight"
            phoneFlashlight.Brightness = 2.5
            phoneFlashlight.Range = 35
            phoneFlashlight.Angle = 50
            phoneFlashlight.Face = Enum.NormalId.Front
            phoneFlashlight.Parent = root
        end
    end
end

Player.CharacterRemoving:Connect(cleanup)
Player.CharacterAdded:Connect(onCharacterAdded)
if Player.Character then onCharacterAdded(Player.Character) end
