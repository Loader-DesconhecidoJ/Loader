local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

pcall(function()
    UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
end)

local function NeutralizeLightingAndFilters(obj)
    if obj:IsA("PostEffect") then
        pcall(function()
            obj.Enabled = false
            
            if obj:IsA("ColorCorrectionEffect") then
                obj.Brightness = 0
                obj.Contrast = 0
                obj.Saturation = 0
                obj.TintColor = Color3.new(1, 1, 1)
            elseif obj:IsA("BlurEffect") then
                obj.Size = 0
            elseif obj:IsA("BloomEffect") then
                obj.Intensity = 0
                obj.Size = 0
                obj.Threshold = 999
            elseif obj:IsA("SunRaysEffect") then
                obj.Intensity = 0
                obj.Spread = 0
            elseif obj:IsA("DepthOfFieldEffect") then
                obj.FocusDistance = 0
                obj.InFocusRadius = 999
                obj.NearIntensity = 0
                obj.FarIntensity = 0
            end

            obj:GetPropertyChangedSignal("Enabled"):Connect(function()
                if obj.Enabled then obj.Enabled = false end
            end)
        end)
    elseif obj:IsA("Light") then 
        pcall(function()
            obj.Enabled = false
            obj.Brightness = 0
            obj.Shadows = false
        end)
    end
end

local function IsPartOfCharacter(obj)
    local current = obj
    while current and current ~= Workspace do
        if current:IsA("Model") then
            if current:FindFirstChildOfClass("Humanoid") then
                return true
            end
            for _, plr in ipairs(Players:GetPlayers()) do
                if current.Name == plr.Name then
                    return true
                end
            end
        end
        current = current.Parent
    end
    return false
end

local function NukeVFX(obj)
    if IsPartOfCharacter(obj) then
        local className = obj.ClassName
        if className == "ParticleEmitter" or className == "Beam" or 
           className == "Fire" or className == "Smoke" or className == "Sparkles" then
            
            task.defer(function()
                pcall(function() obj:Destroy() end)
            end)
        end
        return
    end

    local className = obj.ClassName
    
    if obj:IsA("PostEffect") or obj:IsA("Light") then
        task.defer(NeutralizeLightingAndFilters, obj)
        return
    end

    if className == "ParticleEmitter" or className == "Beam" or 
       className == "Fire" or className == "Smoke" or className == "Sparkles" then
        
        task.defer(function()
            pcall(function() obj:Destroy() end)
        end)
    end

    if obj:IsA("Decal") or obj:IsA("Texture") then
        task.defer(function()
            pcall(function() obj:Destroy() end)
        end)
    end

    if obj:IsA("MeshPart") or obj:IsA("SpecialMesh") or obj:IsA("FileMesh") then
        task.defer(function()
            pcall(function()
                if obj:IsA("MeshPart") then
                    obj.TextureID = ""
                    obj.Material = Enum.Material.Plastic
                    obj.Reflectance = 0
                    obj.CastShadow = false
                end
                obj:Destroy()
            end)
        end)
    end

    if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
        if obj.Parent == Workspace or (obj.Parent and obj.Parent:IsA("Folder") or obj.Parent:IsA("Model") and not obj.Parent:FindFirstChildOfClass("Humanoid")) then
            if obj.Anchored == false or obj.Name:lower():find("loose") or obj.Name:lower():find("solta") or obj.Name:lower():find("debris") then
                task.defer(function()
                    pcall(function()
                        obj:Destroy()
                    end)
                end)
            end
        end
    end

    -- Remove sons loopados / congelados que ficam tocando infinitamente
    if obj:IsA("Sound") then
        task.defer(function()
            pcall(function()
                if obj.Looped or obj.IsPlaying then
                    obj:Stop()
                    obj.Looped = false
                    obj.Volume = 0
                    obj.Playing = false
                end
                obj:Destroy()
            end)
        end)
    end
end

local function CleanStaticObjects()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if IsPartOfCharacter(obj) then
            continue
        end

        if obj:IsA("Decal") or obj:IsA("Texture") then
            pcall(function() obj:Destroy() end)
        end

        if obj:IsA("MeshPart") or obj:IsA("SpecialMesh") or obj:IsA("FileMesh") then
            pcall(function()
                if obj:IsA("MeshPart") then
                    obj.TextureID = ""
                    obj.Material = Enum.Material.Plastic
                    obj.Reflectance = 0
                    obj.CastShadow = false
                end
                obj:Destroy()
            end)
        end

        if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or 
           obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            pcall(function() obj:Destroy() end)
        end

        if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
            if obj.Parent == Workspace or (obj.Parent and (obj.Parent:IsA("Folder") or (obj.Parent:IsA("Model") and not obj.Parent:FindFirstChildOfClass("Humanoid")))) then
                if obj.Anchored == false or obj.Name:lower():find("loose") or obj.Name:lower():find("solta") or obj.Name:lower():find("debris") then
                    pcall(function()
                        obj:Destroy()
                    end)
                end
            end
        end

        -- Limpa sons loopados / congelados no mapa
        if obj:IsA("Sound") then
            pcall(function()
                if obj.Looped or obj.IsPlaying then
                    obj:Stop()
                    obj.Looped = false
                    obj.Volume = 0
                    obj.Playing = false
                end
                obj:Destroy()
            end)
        end
    end
end

local function CleanLightingAndGui()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.fromRGB(150, 150, 150)
        Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
        
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("Sky") or effect:IsA("Atmosphere") then
                effect:Destroy()
            else
                NeutralizeLightingAndFilters(effect)
            end
        end

        local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if PlayerGui then
            for _, gui in ipairs(PlayerGui:GetDescendants()) do
                if gui:IsA("PostEffect") then
                    NeutralizeLightingAndFilters(gui)
                end
            end
        end
    end)
end

task.spawn(function()
    CleanStaticObjects()
    CleanLightingAndGui()
end)

Workspace.DescendantAdded:Connect(NukeVFX)
Lighting.DescendantAdded:Connect(NukeVFX)

if Camera then
    for _, obj in ipairs(Camera:GetDescendants()) do NukeVFX(obj) end
    Camera.DescendantAdded:Connect(NukeVFX)
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local newCam = Workspace.CurrentCamera
    if newCam then
        newCam.DescendantAdded:Connect(NukeVFX)
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        char.DescendantAdded:Connect(NukeVFX)
    end)
end)
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        player.Character.DescendantAdded:Connect(NukeVFX)
    end
end

local function FixCameraOnSpawn(char)
    task.spawn(function()
        local humanoid = char:WaitForChild("Humanoid", 8)
        if humanoid then
            local cam = Workspace.CurrentCamera
            if cam then
                cam.CameraSubject = humanoid
                cam.CameraType = Enum.CameraType.Custom
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(FixCameraOnSpawn)
if LocalPlayer.Character then
    FixCameraOnSpawn(LocalPlayer.Character)
end

RunService.Stepped:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.CameraOffset ~= Vector3.zero then
                humanoid.CameraOffset = Vector3.zero
            end
        end
    end)
end)
