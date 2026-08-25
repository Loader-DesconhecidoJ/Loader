-- =========================================================
-- SISTEMA TZE PHONE - REFORMULADO
-- =========================================================
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local isTouchDevice = UserInputService.TouchEnabled

-- =========================================================
-- SISTEMA DE PASTAS E CONFIGURAÇÃO (SAVE/LOAD)
-- =========================================================
local function criarPastas()
    pcall(function()
        if not isfolder("PHONE") then makefolder("PHONE") end
        if not isfolder("PHONE/Music") then makefolder("PHONE/Music") end
        if not isfolder("PHONE/Photos") then makefolder("PHONE/Photos") end
    end)
end
criarPastas()

local configPath = "PHONE/config.json"
local mySettings = {
    Wallpaper = "rbxassetid://12506271392",
    FPS = false,
    ButtonPos = {0.5, 0, 0.9, -30}
}

local function loadSettings()
    pcall(function()
        if isfile and isfile(configPath) then
            local data = readfile(configPath)
            local decoded = HttpService:JSONDecode(data)
            if decoded then
                for k, v in pairs(decoded) do
                    mySettings[k] = v
                end
            end
        end
    end)
end

local function saveSettings()
    pcall(function()
        if writefile then
            local data = HttpService:JSONEncode(mySettings)
            writefile(configPath, data)
        end
    end)
end

loadSettings()

-- =========================================================
-- INTERFACE PRINCIPAL
-- =========================================================
if CoreGui:FindFirstChild("TzePhoneSystem") then
    CoreGui.TzePhoneSystem:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TzePhoneSystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- =========================================================
-- BOTÃO FLUTUANTE DO PHONE (COM SISTEMA DE ARRASTAR)
-- =========================================================
local PhoneOpenBtn = Instance.new("TextButton")
PhoneOpenBtn.Name = "PhoneFloatingBtn"
PhoneOpenBtn.Size = UDim2.new(0, 44, 0, 44)
PhoneOpenBtn.Position = UDim2.new(mySettings.ButtonPos[1], mySettings.ButtonPos[2], mySettings.ButtonPos[3], mySettings.ButtonPos[4])
PhoneOpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
PhoneOpenBtn.Text = "📱"
PhoneOpenBtn.TextSize = 22
PhoneOpenBtn.Parent = ScreenGui
Instance.new("UICorner", PhoneOpenBtn).CornerRadius = UDim.new(0, 12)

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(50, 205, 50)
btnStroke.Thickness = 2
btnStroke.Parent = PhoneOpenBtn

local holdTime = 0.45
local isHolding = false
local isDragging = false
local holdStart = 0
local dragStart, startPos

PhoneOpenBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isHolding = true
        holdStart = os.clock()
        
        local holdConnection
        holdConnection = RunService.RenderStepped:Connect(function()
            if not isHolding then holdConnection:Disconnect() return end
            if os.clock() - holdStart >= holdTime and not isDragging then
                isDragging = true
                -- Animação de Arrastar
                TweenService:Create(PhoneOpenBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 52, 0, 52),
                    BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                }):Play()
                dragStart = input.Position
                startPos = PhoneOpenBtn.Position
                holdConnection:Disconnect()
            end
        end)
    end
end)

PhoneOpenBtn.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        PhoneOpenBtn.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

PhoneOpenBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isHolding = false
        if isDragging then
            isDragging = false
            -- Animação ao Soltar
            TweenService:Create(PhoneOpenBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 44, 0, 44),
                BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            }):Play()
            -- Salva a posição
            mySettings.ButtonPos = {
                PhoneOpenBtn.Position.X.Scale, PhoneOpenBtn.Position.X.Offset,
                PhoneOpenBtn.Position.Y.Scale, PhoneOpenBtn.Position.Y.Offset
            }
            saveSettings()
        else
            if os.clock() - holdStart < holdTime then
                togglePhone()
            end
        end
    end
end)


-- =========================================================
-- ESTRUTURA DO PHONE
-- =========================================================
local phoneUIScale = Instance.new("UIScale", ScreenGui)
local function updatePhoneScale()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local size = cam.ViewportSize
    local scale = math.clamp(math.min(size.X / 380, size.Y / 620), 0.55, 1.25)
    if isTouchDevice then scale = math.clamp(scale * 1.05, 0.6, 1.35) end
    phoneUIScale.Scale = scale
end
updatePhoneScale()
if Workspace.CurrentCamera then Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePhoneScale) end

local PhoneHome = Instance.new("Frame")
PhoneHome.Name = "PhoneHome"
PhoneHome.Size = UDim2.new(0, 280, 0, 440)
PhoneHome.Position = UDim2.new(0.5, -140, 1.5, 0)
PhoneHome.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
PhoneHome.BorderSizePixel = 0
PhoneHome.Visible = false
PhoneHome.Parent = ScreenGui
Instance.new("UICorner", PhoneHome).CornerRadius = UDim.new(0, 28)

local homeBezel = Instance.new("UIStroke")
homeBezel.Color = Color3.fromRGB(50, 205, 50)
homeBezel.Thickness = 6
homeBezel.Parent = PhoneHome

local homeBg = Instance.new("ImageLabel")
homeBg.Size = UDim2.new(1, 0, 1, 0)
homeBg.BackgroundTransparency = 1
homeBg.Image = mySettings.Wallpaper
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

local homeNotch = Instance.new("Frame")
homeNotch.Size = UDim2.new(0, 82, 0, 24)
homeNotch.Position = UDim2.new(0.5, -41, 0, 9)
homeNotch.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
homeNotch.ZIndex = 5
homeNotch.Parent = PhoneHome
Instance.new("UICorner", homeNotch).CornerRadius = UDim.new(1, 0)

local homeStatus = Instance.new("TextLabel")
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

task.spawn(function()
    while true do
        homeStatus.Text = os.date("%H:%M")
        task.wait(1)
    end
end)

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0.5, -10, 0, 22)
fpsLabel.Position = UDim2.new(0.5, 0, 0, 40)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: --"
fpsLabel.TextColor3 = Color3.fromRGB(50, 205, 50)
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 13
fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
fpsLabel.Visible = mySettings.FPS
fpsLabel.ZIndex = 5
fpsLabel.Parent = PhoneHome

local appsContainer = Instance.new("Frame")
appsContainer.Size = UDim2.new(1, -40, 0, 300)
appsContainer.Position = UDim2.new(0, 20, 0, 80)
appsContainer.BackgroundTransparency = 1
appsContainer.ZIndex = 5
appsContainer.Parent = PhoneHome

local function createNavBar(parent)
    local navBar = Instance.new("Frame")
    navBar.Size = UDim2.new(1, -20, 0, 30)
    navBar.Position = UDim2.new(0, 10, 1, -38)
    navBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    navBar.BackgroundTransparency = 0.4
    navBar.ZIndex = 20
    navBar.Parent = parent
    Instance.new("UICorner", navBar).CornerRadius = UDim.new(0, 14)

    local homeBtn = Instance.new("TextButton")
    homeBtn.Size = UDim2.new(0, 28, 0, 28)
    homeBtn.Position = UDim2.new(0.5, -14, 0.5, -14)
    homeBtn.BackgroundTransparency = 1
    homeBtn.Text = "◯"
    homeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    homeBtn.TextSize = 22
    homeBtn.Font = Enum.Font.GothamBold
    homeBtn.ZIndex = 21
    homeBtn.Parent = navBar

    return homeBtn
end

local function createAppIcon(emoji, color, pos)
    local icon = Instance.new("TextButton")
    icon.Size = UDim2.new(0, 56, 0, 56)
    icon.Position = pos
    icon.BackgroundTransparency = 1
    icon.Text = ""
    icon.ZIndex = 6
    icon.Parent = appsContainer

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = color
    bg.ZIndex = 6
    bg.Parent = icon
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 14)

    local emojiLabel = Instance.new("TextLabel")
    emojiLabel.Size = UDim2.new(1, 0, 1, 0)
    emojiLabel.BackgroundTransparency = 1
    emojiLabel.Text = emoji
    emojiLabel.TextSize = 26
    emojiLabel.ZIndex = 7
    emojiLabel.Parent = bg

    -- Removed text from UI button to keep the design minimalist and professional

    return icon
end

-- Botões minimalistas (apenas ícones e cores)
local ConfigAppIcon = createAppIcon("⚙️", Color3.fromRGB(120, 120, 130), UDim2.new(0, 5, 0, 0))
local CameraAppIcon = createAppIcon("📷", Color3.fromRGB(40, 180, 220), UDim2.new(0, 92, 0, 0))
local GalleryAppIcon = createAppIcon("🖼️", Color3.fromRGB(180, 80, 220), UDim2.new(0, 179, 0, 0))

local isPhoneOpen = false

function togglePhone()
    isPhoneOpen = not isPhoneOpen
    if isPhoneOpen then
        PhoneHome.Visible = true
        TweenService:Create(PhoneHome, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -140, 0.5, -220)
        }):Play()
    else
        local tw = TweenService:Create(PhoneHome, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -140, 1.5, 0)
        })
        tw:Play()
        tw.Completed:Connect(function()
            if not isPhoneOpen then PhoneHome.Visible = false end
        end)
    end
end

-- =========================================================
-- CONFIG APP
-- =========================================================
local ConfigFrame = Instance.new("Frame")
ConfigFrame.Size = UDim2.new(1, 0, 1, 0)
ConfigFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
ConfigFrame.Visible = false
ConfigFrame.ZIndex = 10
ConfigFrame.Parent = PhoneHome
Instance.new("UICorner", ConfigFrame).CornerRadius = UDim.new(0, 28)

local cfgTitle = Instance.new("TextLabel")
cfgTitle.Size = UDim2.new(1, 0, 0, 35)
cfgTitle.Position = UDim2.new(0, 0, 0, 40)
cfgTitle.BackgroundTransparency = 1
cfgTitle.Text = "⚙️"
cfgTitle.TextColor3 = Color3.new(1,1,1)
cfgTitle.Font = Enum.Font.GothamBold
cfgTitle.TextSize = 20
cfgTitle.ZIndex = 11
cfgTitle.Parent = ConfigFrame

local cfgScroll = Instance.new("ScrollingFrame")
cfgScroll.Size = UDim2.new(1, -20, 1, -110)
cfgScroll.Position = UDim2.new(0, 10, 0, 80)
cfgScroll.BackgroundTransparency = 1
cfgScroll.ScrollBarThickness = 2
cfgScroll.ZIndex = 11
cfgScroll.Parent = ConfigFrame
local cfgLayout = Instance.new("UIListLayout")
cfgLayout.Padding = UDim.new(0, 8)
cfgLayout.Parent = cfgScroll

-- Wallpaper Input
local wallFrame = Instance.new("Frame")
wallFrame.Size = UDim2.new(1, 0, 0, 50)
wallFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
wallFrame.ZIndex = 11
wallFrame.Parent = cfgScroll
Instance.new("UICorner", wallFrame).CornerRadius = UDim.new(0, 12)

local wallInput = Instance.new("TextBox")
wallInput.Size = UDim2.new(1, -20, 0, 30)
wallInput.Position = UDim2.new(0, 10, 0, 10)
wallInput.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
wallInput.PlaceholderText = "ID (Wallpaper)"
wallInput.Text = mySettings.Wallpaper:gsub("rbxassetid://", "")
wallInput.TextColor3 = Color3.new(1,1,1)
wallInput.Font = Enum.Font.Gotham
wallInput.TextSize = 12
wallInput.ZIndex = 12
wallInput.Parent = wallFrame
Instance.new("UICorner", wallInput).CornerRadius = UDim.new(0, 8)
local wallStroke = Instance.new("UIStroke")
wallStroke.Color = Color3.fromRGB(50, 205, 50)
wallStroke.Parent = wallInput

wallInput.FocusLost:Connect(function()
    local id = wallInput.Text
    if id ~= "" then
        if tonumber(id) then id = "rbxassetid://" .. id end
        mySettings.Wallpaper = id
        homeBg.Image = id
        saveSettings()
    end
end)

local cfgHomeBtn = createNavBar(ConfigFrame)
cfgHomeBtn.MouseButton1Click:Connect(function() ConfigFrame.Visible = false end)
ConfigAppIcon.MouseButton1Click:Connect(function() ConfigFrame.Visible = true end)

-- =========================================================
-- APP CÂMERA (Salva em PHONE/Photos)
-- =========================================================
local CameraFrame = Instance.new("Frame")
CameraFrame.Size = UDim2.new(1, 0, 1, 0)
CameraFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
CameraFrame.Visible = false
CameraFrame.ZIndex = 10
CameraFrame.Parent = PhoneHome
Instance.new("UICorner", CameraFrame).CornerRadius = UDim.new(0, 28)

local camView = Instance.new("Frame")
camView.Size = UDim2.new(1, 0, 0.7, 0)
camView.Position = UDim2.new(0, 0, 0, 40)
camView.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
camView.BorderSizePixel = 0
camView.ZIndex = 11
camView.Parent = CameraFrame

local picIdInput = Instance.new("TextBox")
picIdInput.Size = UDim2.new(1, -40, 0, 35)
picIdInput.Position = UDim2.new(0, 20, 0, 10)
picIdInput.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
picIdInput.BackgroundTransparency = 0.5
picIdInput.PlaceholderText = "ID do cenário/foto..."
picIdInput.Text = ""
picIdInput.TextColor3 = Color3.new(1,1,1)
picIdInput.Font = Enum.Font.Gotham
picIdInput.TextSize = 12
picIdInput.ZIndex = 13
picIdInput.Parent = camView
Instance.new("UICorner", picIdInput).CornerRadius = UDim.new(0, 8)

local shutterBtn = Instance.new("TextButton")
shutterBtn.Size = UDim2.new(0, 64, 0, 64)
shutterBtn.Position = UDim2.new(0.5, -32, 1, -85)
shutterBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
shutterBtn.Text = ""
shutterBtn.ZIndex = 12
shutterBtn.Parent = CameraFrame
Instance.new("UICorner", shutterBtn).CornerRadius = UDim.new(1, 0)
local shutterStroke = Instance.new("UIStroke")
shutterStroke.Color = Color3.fromRGB(150, 150, 150)
shutterStroke.Thickness = 4
shutterStroke.Parent = shutterBtn

local flashFrame = Instance.new("Frame")
flashFrame.Size = UDim2.new(1, 0, 1, 0)
flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flashFrame.BackgroundTransparency = 1
flashFrame.ZIndex = 20
flashFrame.Parent = CameraFrame
Instance.new("UICorner", flashFrame).CornerRadius = UDim.new(0, 28)

shutterBtn.MouseButton1Click:Connect(function()
    flashFrame.BackgroundTransparency = 0
    TweenService:Create(flashFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
    
    local id = picIdInput.Text
    if id == "" or not tonumber(id) then
        id = "12506271392"
    end
    
    local finalId = "rbxassetid://" .. id
    local filename = "PHONE/Photos/Print_" .. tostring(os.time()) .. ".txt"
    
    pcall(function()
        if writefile then
            writefile(filename, finalId)
        end
    end)
    
    picIdInput.Text = ""
    picIdInput.PlaceholderText = "Foto salva!"
    task.delay(2, function() picIdInput.PlaceholderText = "ID do cenário/foto..." end)
end)

local camHomeBtn = createNavBar(CameraFrame)
camHomeBtn.MouseButton1Click:Connect(function() CameraFrame.Visible = false end)
CameraAppIcon.MouseButton1Click:Connect(function() CameraFrame.Visible = true end)

-- =========================================================
-- APP GALERIA
-- =========================================================
local GalleryFrame = Instance.new("Frame")
GalleryFrame.Size = UDim2.new(1, 0, 1, 0)
GalleryFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
GalleryFrame.Visible = false
GalleryFrame.ZIndex = 10
GalleryFrame.Parent = PhoneHome
Instance.new("UICorner", GalleryFrame).CornerRadius = UDim.new(0, 28)

local galScroll = Instance.new("ScrollingFrame")
galScroll.Size = UDim2.new(1, -20, 1, -110)
galScroll.Position = UDim2.new(0, 10, 0, 40)
galScroll.BackgroundTransparency = 1
galScroll.ScrollBarThickness = 2
galScroll.ZIndex = 11
galScroll.Parent = GalleryFrame
local galGrid = Instance.new("UIGridLayout")
galGrid.CellSize = UDim2.new(0, 80, 0, 80)
galGrid.CellPadding = UDim2.new(0, 6, 0, 6)
galGrid.Parent = galScroll

local function refreshGallery()
    for _, child in pairs(galScroll:GetChildren()) do
        if child:IsA("ImageButton") then child:Destroy() end
    end
    
    local success, files = pcall(function() return listfiles("PHONE/Photos") end)
    if success and files then
        for _, file in ipairs(files) do
            if string.match(file, "%.txt$") then
                pcall(function()
                    local id = readfile(file)
                    
                    local imgBtn = Instance.new("ImageButton")
                    imgBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                    imgBtn.Image = id
                    imgBtn.ScaleType = Enum.ScaleType.Crop
                    imgBtn.ZIndex = 12
                    imgBtn.Parent = galScroll
                    Instance.new("UICorner", imgBtn).CornerRadius = UDim.new(0, 8)
                    
                    imgBtn.MouseButton1Click:Connect(function()
                        wallInput.Text = id:gsub("rbxassetid://", "")
                        mySettings.Wallpaper = id
                        homeBg.Image = id
                        saveSettings()
                    end)
                end)
            end
        end
    end
    
    galScroll.CanvasSize = UDim2.new(0, 0, 0, galGrid.AbsoluteContentSize.Y + 20)
end

galGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    galScroll.CanvasSize = UDim2.new(0, 0, 0, galGrid.AbsoluteContentSize.Y + 20)
end)

local galHomeBtn = createNavBar(GalleryFrame)
galHomeBtn.MouseButton1Click:Connect(function() GalleryFrame.Visible = false end)
GalleryAppIcon.MouseButton1Click:Connect(function()
    refreshGallery()
    GalleryFrame.Visible = true
end)
