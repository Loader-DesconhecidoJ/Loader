local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
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
				if obj.Enabled then
					obj.Enabled = false
				end
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

local function SafeDestroySound(sound)
	pcall(function()
		if sound and sound.Parent then
			sound:Stop()
			sound.Looped = false
			sound.Volume = 0
			sound:Destroy()
		end
	end)
end

local function NukeVFX(obj)
	if not obj or not obj.Parent then
		return
	end

	if IsPartOfCharacter(obj) then
		local className = obj.ClassName
		if className == "ParticleEmitter" or className == "Beam" or className == "Fire" or className == "Smoke" or className == "Sparkles" then
			task.defer(function()
				pcall(function()
					obj:Destroy()
				end)
			end)
		end
		return
	end

	if obj:IsA("PostEffect") or obj:IsA("Light") then
		task.defer(NeutralizeLightingAndFilters, obj)
		return
	end

	local className = obj.ClassName

	if className == "ParticleEmitter" or className == "Beam" or className == "Fire" or className == "Smoke" or className == "Sparkles" then
		task.defer(function()
			pcall(function()
				obj:Destroy()
			end)
		end)
		return
	end

	if obj:IsA("Decal") or obj:IsA("Texture") then
		task.defer(function()
			pcall(function()
				obj:Destroy()
			end)
		end)
		return
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
		return
	end

	-- Peças soltas (corrigido precedência de operadores)
	if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
		local parent = obj.Parent
		local isLooseParent = parent == Workspace
			or (parent and (parent:IsA("Folder") or (parent:IsA("Model") and not parent:FindFirstChildOfClass("Humanoid"))))

		if isLooseParent then
			local nameLower = string.lower(obj.Name)
			if obj.Anchored == false or nameLower:find("loose") or nameLower:find("solta") or nameLower:find("debris") then
				task.defer(function()
					pcall(function()
						obj:Destroy()
					end)
				end)
			end
		end
		return
	end

	-- Sons loopados / congelados (não destrói sons de personagem)
	if obj:IsA("Sound") then
		if obj.Looped or (obj.IsPlaying and obj.TimeLength > 0 and obj.TimePosition > 0) then
			task.defer(function()
				SafeDestroySound(obj)
			end)
		end
	end
end

local function CleanStaticObjects()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if IsPartOfCharacter(obj) then
			continue
		end

		if obj:IsA("Decal") or obj:IsA("Texture") then
			pcall(function()
				obj:Destroy()
			end)
		elseif obj:IsA("MeshPart") or obj:IsA("SpecialMesh") or obj:IsA("FileMesh") then
			pcall(function()
				if obj:IsA("MeshPart") then
					obj.TextureID = ""
					obj.Material = Enum.Material.Plastic
					obj.Reflectance = 0
					obj.CastShadow = false
				end
				obj:Destroy()
			end)
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
			pcall(function()
				obj:Destroy()
			end)
		elseif obj:IsA("BasePart") and not obj:IsA("MeshPart") then
			local parent = obj.Parent
			local isLooseParent = parent == Workspace
				or (parent and (parent:IsA("Folder") or (parent:IsA("Model") and not parent:FindFirstChildOfClass("Humanoid"))))

			if isLooseParent then
				local nameLower = string.lower(obj.Name)
				if obj.Anchored == false or nameLower:find("loose") or nameLower:find("solta") or nameLower:find("debris") then
					pcall(function()
						obj:Destroy()
					end)
				end
			end
		elseif obj:IsA("Sound") then
			if obj.Looped or obj.IsPlaying then
				SafeDestroySound(obj)
			end
		end
	end

	-- Limpa também sons presos no SoundService
	for _, obj in ipairs(SoundService:GetDescendants()) do
		if obj:IsA("Sound") and (obj.Looped or obj.IsPlaying) then
			SafeDestroySound(obj)
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

-- Limpeza inicial
task.spawn(function()
	CleanStaticObjects()
	CleanLightingAndGui()
end)

-- Limpeza periódica de sons (evita acúmulo)
task.spawn(function()
	while true do
		task.wait(8)
		pcall(function()
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("Sound") and not IsPartOfCharacter(obj) then
					if obj.Looped or (obj.IsPlaying and obj.Volume > 0) then
						SafeDestroySound(obj)
					end
				end
			end
			for _, obj in ipairs(SoundService:GetDescendants()) do
				if obj:IsA("Sound") and (obj.Looped or obj.IsPlaying) then
					SafeDestroySound(obj)
				end
			end
		end)
	end
end)

Workspace.DescendantAdded:Connect(NukeVFX)
Lighting.DescendantAdded:Connect(NukeVFX)
SoundService.DescendantAdded:Connect(function(obj)
	if obj:IsA("Sound") then
		task.defer(function()
			if obj.Looped or obj.IsPlaying then
				SafeDestroySound(obj)
			end
		end)
	end
end)

if Camera then
	for _, obj in ipairs(Camera:GetDescendants()) do
		NukeVFX(obj)
	end
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
