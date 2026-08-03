local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Enabled, LockedTarget = false, nil
local Mode = "PLAYER"
local Device = "Mobile"
local SEARCH_DISTANCE = 55
local FULL_NECK_DISTANCE, FULL_ROOT_DISTANCE = 22, 7
local lastSearchTime, SEARCH_RATE = 0, 0.25

local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("LockOnScreenGui")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LockOnScreenGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function getTargetPart(character)
	return character and character:FindFirstChild("Head")
end

local function getNeckPosition(head)
	if not head then return nil end
	local char = head.Parent
	if not char then return nil end
	local neckAtt = head:FindFirstChild("NeckAttachment") or (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")):FindFirstChild("NeckAttachment")
	if neckAtt and neckAtt:IsA("Attachment") then
		return neckAtt.WorldPosition
	end
	return (head.CFrame * CFrame.new(0, -0.5, 0)).Position
end

local function getCameraLockPosition(targetPart)
	if not targetPart then return nil end
	local char = targetPart.Parent
	local myChar = LocalPlayer.Character
	if not myChar or not char then return getNeckPosition(targetPart) end

	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	local targetRoot = char:FindFirstChild("HumanoidRootPart")
	if not myRoot or not targetRoot then return getNeckPosition(targetPart) end

	local neckPos = getNeckPosition(targetPart)
	local distance = (myRoot.Position - targetRoot.Position).Magnitude

	if distance >= FULL_NECK_DISTANCE then
		return neckPos
	elseif distance <= FULL_ROOT_DISTANCE then
		return targetRoot.Position
	else
		return targetRoot.Position:Lerp(neckPos, (distance - FULL_ROOT_DISTANCE) / (FULL_NECK_DISTANCE - FULL_ROOT_DISTANCE))
	end
end

local function setupDeathHandler(char)
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Died:Connect(function()
				Enabled = false
				LockedTarget = nil
			end)
		end
	end
end

local function findClosestTarget()
	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	local closest, minDist = nil, math.huge
	local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	overlapParams.FilterDescendantsInstances = {LocalPlayer.Character}
	local nearbyParts = Workspace:GetPartBoundsInRadius(myRoot.Position, SEARCH_DISTANCE, overlapParams)
	local checked = {}

	for _, part in ipairs(nearbyParts) do
		local char = part:FindFirstAncestorWhichIsA("Model")
		if char and not checked[char] and char ~= LocalPlayer.Character then
			checked[char] = true
			local isPlayer = Players:GetPlayerFromCharacter(char)
			local hum = char:FindFirstChildOfClass("Humanoid")

			if hum and hum.Health > 0 then
				local valid = false
				if Mode == "PLAYER" and isPlayer then
					valid = true
				elseif Mode == "NPC" and not isPlayer then
					valid = true
				end

				if valid then
					local tPart = getTargetPart(char)
					local pos = tPart and getNeckPosition(tPart)
					if pos then
						local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
						if onScreen then
							local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
							if dist < minDist then
								minDist = dist
								closest = tPart
							end
						end
					end
				end
			end
		end
	end
	return closest
end

local function isValidTarget(t)
	if not t or not t.Parent then return false end
	local isPlayer = Players:GetPlayerFromCharacter(t.Parent)
	local hum = t.Parent:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or t.Parent == LocalPlayer.Character then return false end

	if Mode == "PLAYER" then
		return isPlayer ~= nil
	else
		return isPlayer == nil
	end
end

local toggleBtn, billboard, modeLabel
local lastClickTime = 0
local clickThread = nil
local isDragging = false

local function playClickAnimation()
	if not toggleBtn or not toggleBtn.Visible then return end
	local originalSize = UDim2.new(0, 85, 0, 85)
	local shrink = TweenService:Create(toggleBtn, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 72, 0, 72)})
	local grow = TweenService:Create(toggleBtn, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = originalSize})
	shrink:Play()
	shrink.Completed:Connect(function() grow:Play() end)
end

local function playHoldAnimation(state)
	if not toggleBtn or not toggleBtn.Visible then return end
	if state then
		TweenService:Create(toggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 78, 0, 78),
			ImageTransparency = 0.15
		}):Play()
	else
		TweenService:Create(toggleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 85, 0, 85),
			ImageTransparency = 0
		}):Play()
	end
end

local function showModeText(text, color)
	if modeLabel then
		local out = TweenService:Create(modeLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			Position = modeLabel.Position + UDim2.new(0, 0, 0, -15)
		})
		out:Play()
		out.Completed:Wait()
		modeLabel:Destroy()
	end

	modeLabel = Instance.new("TextLabel")
	modeLabel.Name = "ModeLabel"
	modeLabel.Size = UDim2.new(0, 160, 0, 42)
	modeLabel.Position = UDim2.new(0.5, -80, 0, 20)
	modeLabel.BackgroundTransparency = 1
	modeLabel.Text = text
	modeLabel.Font = Enum.Font.GothamBlack
	modeLabel.TextSize = 28
	modeLabel.TextColor3 = color
	modeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	modeLabel.TextStrokeTransparency = 0.3
	modeLabel.TextTransparency = 1
	modeLabel.Parent = screenGui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3.5
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Transparency = 0.2
	stroke.Parent = modeLabel

	local gradient = Instance.new("UIGradient")
	if text == "NPC" then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 40, 40))
		})
	else
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 140, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 200, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 100, 255))
		})
	end
	gradient.Rotation = 45
	gradient.Parent = modeLabel

	modeLabel.Position = UDim2.new(0.5, -80, 0, -20)
	TweenService:Create(modeLabel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextStrokeTransparency = 0.3,
		Position = UDim2.new(0.5, -80, 0, 25)
	}):Play()

	task.delay(1.6, function()
		if modeLabel and modeLabel.Parent then
			local fade = TweenService:Create(modeLabel, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
				TextTransparency = 1,
				TextStrokeTransparency = 1,
				Position = modeLabel.Position + UDim2.new(0, 0, 0, -18)
			})
			fade:Play()
			fade.Completed:Connect(function()
				if modeLabel then modeLabel:Destroy() end
			end)
		end
	end)
end

local function switchMode()
	playClickAnimation()
	task.wait(0.08)

	if Mode == "NPC" then
		Mode = "PLAYER"
		showModeText("PLAYER", Color3.fromRGB(60, 160, 255))
	else
		Mode = "NPC"
		showModeText("NPC", Color3.fromRGB(255, 70, 70))
	end

	LockedTarget = nil
	if Enabled then
		LockedTarget = findClosestTarget()
	end
end

local function toggleLock()
	playClickAnimation()
	Enabled = not Enabled
	LockedTarget = Enabled and findClosestTarget() or nil

	if not Enabled then
		if billboard then billboard.Enabled = false end
	end

	if toggleBtn and toggleBtn.Visible then
		toggleBtn.Image = Enabled and "rbxassetid://113252099863593" or "rbxassetid://73466246454364"
	end
end

local function preLoadUI()
	toggleBtn = Instance.new("ImageButton", screenGui)
	toggleBtn.Size = UDim2.new(0, 85, 0, 85)
	toggleBtn.Position = UDim2.new(1, -95, 0, 10)
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Image = "rbxassetid://73466246454364"
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
	toggleBtn.Visible = false

	billboard = Instance.new("BillboardGui", screenGui)
	billboard.AlwaysOnTop = true
	billboard.Enabled = false
	local ind = Instance.new("ImageLabel", billboard)
	ind.Size = UDim2.new(1,0,1,0)
	ind.BackgroundTransparency = 1
	ind.Image = "rbxassetid://125342227220370"
	ind.ImageTransparency = 0.5
	ind.ImageColor3 = Color3.fromRGB(255,255,255)
	Instance.new("UICorner", ind).CornerRadius = UDim.new(1,0)

	local hold, canDrag, startPos, dragStart = false, false, nil, nil

	toggleBtn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			hold = true
			startPos = toggleBtn.Position
			dragStart = i.Position
			playHoldAnimation(true)
			task.delay(0.45, function()
				if hold then
					canDrag = true
					isDragging = true
				end
			end)
		end
	end)

	toggleBtn.InputChanged:Connect(function(i)
		if canDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local delta = i.Position - dragStart
			toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	toggleBtn.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			hold = false
			canDrag = false
			isDragging = false
			playHoldAnimation(false)
		end
	end)

	toggleBtn.MouseButton1Click:Connect(function()
		if canDrag or isDragging then return end

		local now = tick()
		if now - lastClickTime < 0.28 then
			if clickThread then
				task.cancel(clickThread)
				clickThread = nil
			end
			switchMode()
			lastClickTime = 0
			return
		end

		lastClickTime = now
		clickThread = task.delay(0.28, function()
			clickThread = nil
			toggleLock()
		end)
	end)
end
preLoadUI()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.L then
		toggleLock()
	elseif input.KeyCode == Enum.KeyCode.RightControl then
		switchMode()
	end
end)

local function createSettingsMenu()
	local frame = Instance.new("Frame", screenGui)
	frame.Size = UDim2.new(0, 320, 0, 200)
	frame.Position = UDim2.new(0.5, -160, 0.5, -100)
	frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
	Instance.new("UIStroke", frame).Color = Color3.fromRGB(0,255,255)

	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1,0,0,40)
	title.Text = "Settings"
	title.TextColor3 = Color3.new(1,1,1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20

	local deviceLabel = Instance.new("TextLabel", frame)
	deviceLabel.Size = UDim2.new(1, 0, 0, 25)
	deviceLabel.Position = UDim2.new(0, 0, 0, 50)
	deviceLabel.BackgroundTransparency = 1
	deviceLabel.Text = "Dispositivo:"
	deviceLabel.TextColor3 = Color3.fromRGB(200,200,200)
	deviceLabel.Font = Enum.Font.Gotham
	deviceLabel.TextSize = 16

	local mobileBtn = Instance.new("TextButton", frame)
	mobileBtn.Size = UDim2.new(0.4, 0, 0, 36)
	mobileBtn.Position = UDim2.new(0.07, 0, 0, 85)
	mobileBtn.Text = "Mobile"
	mobileBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 180)
	mobileBtn.TextColor3 = Color3.new(1,1,1)
	mobileBtn.Font = Enum.Font.GothamBold
	Instance.new("UICorner", mobileBtn).CornerRadius = UDim.new(0, 8)

	local pcBtn = Instance.new("TextButton", frame)
	pcBtn.Size = UDim2.new(0.4, 0, 0, 36)
	pcBtn.Position = UDim2.new(0.53, 0, 0, 85)
	pcBtn.Text = "PC"
	pcBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
	pcBtn.TextColor3 = Color3.new(1,1,1)
	pcBtn.Font = Enum.Font.GothamBold
	Instance.new("UICorner", pcBtn).CornerRadius = UDim.new(0, 8)

	local selectedDevice = "Mobile"

	mobileBtn.MouseButton1Click:Connect(function()
		selectedDevice = "Mobile"
		mobileBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 180)
		pcBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
	end)

	pcBtn.MouseButton1Click:Connect(function()
		selectedDevice = "PC"
		pcBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 180)
		mobileBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
	end)

	local confirmBtn = Instance.new("TextButton", frame)
	confirmBtn.Size = UDim2.new(0.85, 0, 0, 40)
	confirmBtn.Position = UDim2.new(0.075, 0, 0, 140)
	confirmBtn.Text = "Confirm"
	confirmBtn.BackgroundColor3 = Color3.fromRGB(0,200,200)
	confirmBtn.TextColor3 = Color3.new(1,1,1)
	confirmBtn.Font = Enum.Font.GothamBold
	Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0,8)

	confirmBtn.MouseButton1Click:Connect(function()
		Device = selectedDevice
		frame:Destroy()

		if Device == "Mobile" then
			toggleBtn.Visible = true
		else
			toggleBtn.Visible = false
		end

		task.defer(function()
			pcall(function()
				local text = Device == "Mobile" and "Mobile Mode" or "PC Mode - L / RightCtrl"
				StarterGui:SetCore("SendNotification", {
					Title = "Lock On",
					Text = text,
					Icon = "rbxassetid://7205866966",
					Duration = 5
				})
			end)
		end)
	end)
end

createSettingsMenu()
if LocalPlayer.Character then setupDeathHandler(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupDeathHandler)

local lastBill = 0

RunService:BindToRenderStep("LockCameraLoop", 201, function()
	if not Enabled then
		if billboard then billboard.Enabled = false end
		return
	end

	local now = tick()
	if now - lastSearchTime > SEARCH_RATE then
		if not isValidTarget(LockedTarget) then
			LockedTarget = findClosestTarget()
		end
		lastSearchTime = now
	end

	if LockedTarget and LockedTarget.Parent then
		local lockPos = getCameraLockPosition(LockedTarget)
		if lockPos then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, lockPos)
		end

		local tPart = LockedTarget.Parent:FindFirstChild("UpperTorso") or LockedTarget.Parent:FindFirstChild("Torso") or LockedTarget.Parent:FindFirstChild("HumanoidRootPart")
		if tPart then
			billboard.Adornee = tPart
			billboard.Enabled = true
			if now - lastBill > 0.1 then
				local scale = math.clamp(LockedTarget.Size.Y * 2.5, 3.0, 10.0)
				billboard.Size = UDim2.new(0, (1400 / ((Camera.CFrame.Position - tPart.Position).Magnitude + 8)) * scale, 0, (1400 / ((Camera.CFrame.Position - tPart.Position).Magnitude + 8)) * scale)
				lastBill = now
			end
		else
			billboard.Enabled = false
		end
	else
		if billboard then billboard.Enabled = false end
	end
end)
