local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local KEYBIND = Enum.KeyCode.R

local SOUNDS_RAGDOLL = {
    "83123564520089",
    "91358197736651",
    "125172888675723",
    "70742968288690",
}
local SOUND_GETUP = "136774133309136"
local SOUND_JUMP = "73013473893740"
local SOUND_VOLUME = 1
local GETUP_TIME = 0.7

local JUMP_POWER = 90
local JUMP_PUSH = 30

local IMPACT_MIN_SPEED = 6
local IMPACT_COOLDOWN = 0.25
local JUMP_COOLDOWN = 0.6
local JUMP_NEEDS_GROUND = true

local function playSound(ids, parent)
    if not parent then return end
    local id = type(ids) == "table" and ids[math.random(#ids)] or ids
    local ok = pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://" .. id
        s.Volume = SOUND_VOLUME
        s.RollOffMaxDistance = 120
        s.Parent = parent
        s:Play()
        Debris:AddItem(s, 10)
    end)
    return ok
end

local env = (getgenv and getgenv()) or _G
if env.__RagdollCleanup then
    pcall(env.__RagdollCleanup)
end

local LIMITS = {
    Neck = {cone = 50, twist = 40},
    Shoulder = {cone = 110, twist = 60},
    Hip = {cone = 80, twist = 35},
    Knee = {cone = 70, twist = 10},
    Elbow = {cone = 80, twist = 10},
    Ankle = {cone = 35, twist = 15},
    Wrist = {cone = 40, twist = 20},
    Waist = {cone = 35, twist = 20},
    Default = {cone = 50, twist = 25},
}

local JOINT_FREEDOM = 1.3
local USE_HINGES = true
local MOMENTUM_KEEP = 1
local SPIN_DAMPING = 0.8
local LIMB_FRICTION = 0.8
local LIMB_ELASTICITY = 0.05
local DENSITY = {Head = 1.0, Torso = 1.0, Limb = 0.6}
local NEVER_STAND = true
local STAND_LIMIT = 0.4
local TIP_TORQUE = 38
local TIP_MAX_SPIN = 7
local FLAT_SLOPE = 0.03
local TIP_GROUND_RANGE = 7

local VFX_ENABLED = true
local AIR_VFX_MIN_SPEED = 35
local IMPACT_VFX_MIN_SPEED = 14
local TRAIL_DELAY = 2
local TRAIL_FADE = 1.5
local AUTO_RAGDOLL = true
local AUTO_RAGDOLL_DELAY = TRAIL_DELAY
local SHAKE_POWER = 1
local AIR_SHAKE = 0.25
local FOV_BOOST = 12
local STABLE_CAMERA = true

local function getLimits(name)
    local base = LIMITS.Default
    for key, v in pairs(LIMITS) do
        if key ~= "Default" and name:find(key) then
            base = v
            break
        end
    end
    return {
        cone = math.min(base.cone * JOINT_FREEDOM, 175),
        twist = math.min(base.twist * JOINT_FREEDOM, 175),
    }
end

local function getDensity(partName)
    if partName == "Head" then return DENSITY.Head end
    if partName:find("Torso") then return DENSITY.Torso end
    return DENSITY.Limb
end

local ragdolled = false
local gettingUp = false
local lastImpact = 0
local ragConns = {}
local created = {}
local motors = {}
local collideBackup = {}
local physBackup = {}
local connections = {}

local ui = {}
local setRagdoll
local camSubjectBackup = nil

local function getChar()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    return char, hum, root
end

local vfx = {
    air = 0,
    shake = 0,
    airTime = 0,
    trail = 0,
    rayParams = nil,
    trails = {},
    trailChar = nil,
    fovActive = false,
    baseFov = 70,
    folder = nil,
}

local function fxFolder()
    if not vfx.folder or not vfx.folder.Parent then
        local f = Instance.new("Folder")
        f.Name = "RagdollFX"
        f.Parent = workspace
        vfx.folder = f
    end
    return vfx.folder
end

local TRAIL_PARTS = {
    "Head", "LeftHand", "RightHand", "LeftFoot", "RightFoot",
    "Left Arm", "Right Arm", "Left Leg", "Right Leg",
}

local function clearTrails()
    for _, inst in ipairs(vfx.trails) do
        if inst and inst.Parent then inst:Destroy() end
    end
    table.clear(vfx.trails)
    vfx.trailChar = nil
end

local function ensureTrails(char)
    if vfx.trailChar == char then return end
    clearTrails()
    vfx.trailChar = char
    for _, name in ipairs(TRAIL_PARTS) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            local a0 = Instance.new("Attachment")
            a0.Name = "FXTrailA0"
            a0.Position = Vector3.new(0, p.Size.Y * 0.35, 0)
            a0.Parent = p

            local a1 = Instance.new("Attachment")
            a1.Name = "FXTrailA1"
            a1.Position = Vector3.new(0, -p.Size.Y * 0.35, 0)
            a1.Parent = p

            local t = Instance.new("Trail")
            t.Name = "FXTrail"
            t.Attachment0 = a0
            t.Attachment1 = a1
            t.Lifetime = 0.3
            t.MinLength = 0.05
            t.FaceCamera = true
            t.LightEmission = 0.5
            t.Color = ColorSequence.new(Color3.fromRGB(235, 245, 255))
            t.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.35),
                NumberSequenceKeypoint.new(1, 1),
            })
            t.WidthScale = NumberSequence.new(1, 0.2)
            t.Enabled = false
            t.Parent = p

            table.insert(vfx.trails, a0)
            table.insert(vfx.trails, a1)
            table.insert(vfx.trails, t)
        end
    end
end

local function spawnDust(pos, normal, speed, color)
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Transparency = 1
    part.Size = Vector3.new(1, 1, 1)
    part.CFrame = CFrame.new(pos, pos + normal) * CFrame.Angles(-math.pi / 2, 0, 0)
    part.Parent = fxFolder()

    local s = math.clamp(speed / 30, 0.6, 2)
    local e = Instance.new("ParticleEmitter")
    e.Texture = "rbxasset://textures/particles/smoke_main.dds"
    e.Color = ColorSequence.new(color:Lerp(Color3.fromRGB(190, 190, 190), 0.5))
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8 * s),
        NumberSequenceKeypoint.new(1, 2.8 * s),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.35),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.Lifetime = NumberRange.new(0.5, 1.1)
    e.Speed = NumberRange.new(5 * s, 12 * s)
    e.SpreadAngle = Vector2.new(75, 75)
    e.Drag = 3
    e.Rotation = NumberRange.new(0, 360)
    e.RotSpeed = NumberRange.new(-90, 90)
    e.EmissionDirection = Enum.NormalId.Top
    e.Rate = 0
    e.Parent = part
    e:Emit(math.clamp(math.floor(speed * 0.6), 6, 30))

    Debris:AddItem(part, 2)
end

local function vfxImpactAt(pos, normal, speed, color)
    spawnDust(pos, normal, speed, color)
    if speed >= 20 then
        vfx.shake = math.max(vfx.shake, math.clamp(speed / 70, 0.15, 1) * SHAKE_POWER)
    end
end

local function vfxImpact(part, other, speed, char)
    if not VFX_ENABLED or speed < IMPACT_VFX_MIN_SPEED then return end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, fxFolder()}
    local res = workspace:Raycast(part.Position + Vector3.new(0, 1, 0), Vector3.new(0, -6, 0), params)
    local pos = res and res.Position or part.Position
    local normal = res and res.Normal or Vector3.yAxis
    vfxImpactAt(pos, normal, speed, other.Color)
end

local function vfxStep(dt)
    local cam = workspace.CurrentCamera
    local char, hum, root = getChar()

    if char and hum and root and hum.Health > 0 then
        if not vfx.rayParams then
            vfx.rayParams = RaycastParams.new()
            vfx.rayParams.FilterType = Enum.RaycastFilterType.Exclude
        end
        vfx.rayParams.FilterDescendantsInstances = {char, fxFolder()}
        local airborne = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), vfx.rayParams) == nil
        if airborne and not ragdolled then

            airborne = hum:GetState() == Enum.HumanoidStateType.Freefall
        end
        if airborne and not gettingUp then
            vfx.airTime = vfx.airTime + dt
        else
            vfx.airTime = 0
        end

        if AUTO_RAGDOLL and not ragdolled and not gettingUp
            and vfx.airTime >= AUTO_RAGDOLL_DELAY then
            setRagdoll(true)
        end
    else
        vfx.airTime = 0
    end

    local active = char and root and VFX_ENABLED and ragdolled
    local target = 0
    local trailTarget = 0
    if active then
        ensureTrails(char)
        local speed = root.AssemblyLinearVelocity.Magnitude
        target = math.clamp((speed - AIR_VFX_MIN_SPEED) / 50, 0, 1)
        trailTarget = math.clamp((vfx.airTime - TRAIL_DELAY) / TRAIL_FADE, 0, 1)
    elseif vfx.trailChar then
        clearTrails()
    end

    vfx.air = vfx.air + (target - vfx.air) * math.min(1, dt * 8)
    vfx.trail = vfx.trail + (trailTarget - vfx.trail) * math.min(1, dt * 8)

    local t = vfx.trail
    local on = t > 0.03
    local seq = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1 - 0.65 * t),
        NumberSequenceKeypoint.new(1, 1),
    })
    for _, inst in ipairs(vfx.trails) do
        if inst:IsA("Trail") then
            inst.Enabled = on
            inst.Lifetime = 0.12 + 0.3 * t
            inst.Transparency = seq
        end
    end

    if cam then
        if vfx.air > 0.02 then
            if not vfx.fovActive then
                vfx.baseFov = cam.FieldOfView
                vfx.fovActive = true
            end
            cam.FieldOfView = vfx.baseFov + FOV_BOOST * vfx.air
        elseif vfx.fovActive then
            cam.FieldOfView = vfx.baseFov
            vfx.fovActive = false
        end

        local s = math.max(vfx.shake, vfx.air * AIR_SHAKE)
        if s > 0.01 then

            cam.CFrame = cam.CFrame
                * CFrame.new((math.random() - 0.5) * s * 0.6, (math.random() - 0.5) * s * 0.6, 0)
        end
        vfx.shake = vfx.shake * math.max(0, 1 - 7 * dt)
    end
end

local function vfxCleanup()
    pcall(function() RunService:UnbindFromRenderStep("RagdollFX") end)
    clearTrails()
    local cam = workspace.CurrentCamera
    if cam and vfx.fovActive then cam.FieldOfView = vfx.baseFov end
    if vfx.folder then vfx.folder:Destroy() end
end

local function enableRagdoll()
    local char, hum, root = getChar()
    if not (char and hum and root) or hum.Health <= 0 then return false end

    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("Motor6D") and d.Part0 and d.Part1
            and d.Part0.Name ~= "HumanoidRootPart"
            and d.Part1.Parent == char then

            local lim = getLimits(d.Name)

            local a0 = Instance.new("Attachment")
            a0.Name = "RagA0"
            a0.CFrame = d.C0
            a0.Parent = d.Part0

            local a1 = Instance.new("Attachment")
            a1.Name = "RagA1"
            a1.CFrame = d.C1
            a1.Parent = d.Part1

            local isR15 = hum.RigType == Enum.HumanoidRigType.R15
            local isKnee = d.Name:find("Knee") ~= nil
            local isElbow = d.Name:find("Elbow") ~= nil

            local joint
            if USE_HINGES and isR15 and (isKnee or isElbow) then

                local hinge = Instance.new("HingeConstraint")
                hinge.Name = "RagConstraint"
                hinge.Attachment0 = a0
                hinge.Attachment1 = a1
                hinge.LimitsEnabled = true
                if isKnee then
                    hinge.LowerAngle = -140
                    hinge.UpperAngle = 5
                else
                    hinge.LowerAngle = -5
                    hinge.UpperAngle = 140
                end
                hinge.Restitution = 0
                joint = hinge
            else
                local bs = Instance.new("BallSocketConstraint")
                bs.Name = "RagConstraint"
                bs.Attachment0 = a0
                bs.Attachment1 = a1
                bs.LimitsEnabled = true
                bs.UpperAngle = lim.cone
                bs.TwistLimitsEnabled = true
                bs.TwistLowerAngle = -lim.twist
                bs.TwistUpperAngle = lim.twist
                bs.Restitution = 0
                joint = bs
            end
            joint.Parent = d.Part0

            local nc = Instance.new("NoCollisionConstraint")
            nc.Name = "RagNoCollide"
            nc.Part0 = d.Part0
            nc.Part1 = d.Part1
            nc.Parent = d.Part0

            table.insert(created, a0)
            table.insert(created, a1)
            table.insert(created, joint)
            table.insert(created, nc)

            d.Enabled = false
            table.insert(motors, d)
        end
    end

    local startVel = root.AssemblyLinearVelocity

    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            collideBackup[p] = p.CanCollide
            p.CanCollide = true

            physBackup[p] = {p.CustomPhysicalProperties}
            p.CustomPhysicalProperties = PhysicalProperties.new(
                getDensity(p.Name), LIMB_FRICTION, LIMB_ELASTICITY, 50, 50
            )
        end
    end
    root.CanCollide = false

    hum.AutoRotate = false
    hum.PlatformStand = true
    hum:ChangeState(Enum.HumanoidStateType.Physics)

    if STABLE_CAMERA then
        local cam = workspace.CurrentCamera
        local subject = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if cam and subject then
            camSubjectBackup = cam.CameraSubject
            cam.CameraSubject = subject
        end
    end

    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") then
            p.AssemblyLinearVelocity = startVel * MOMENTUM_KEEP
        end
    end

    if SPIN_DAMPING > 0 then
        table.insert(ragConns, RunService.Heartbeat:Connect(function(dt)
            if not ragdolled or gettingUp then return end
            local f = math.max(0, 1 - SPIN_DAMPING * dt)
            for _, p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") then
                    p.AssemblyAngularVelocity = p.AssemblyAngularVelocity * f
                end
            end
        end))
    end

    if NEVER_STAND then
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {char, fxFolder()}

        local function newRandomDir()
            local a = math.random() * math.pi * 2
            return Vector3.new(math.cos(a), 0, math.sin(a))
        end
        local randomDir = newRandomDir()

        if torso then
            table.insert(ragConns, RunService.Heartbeat:Connect(function(dt)
                if not ragdolled or gettingUp or not torso.Parent then return end

                local up = torso.CFrame.UpVector
                if up.Y <= STAND_LIMIT then
                    randomDir = newRandomDir()
                    return
                end
                if torso.AssemblyLinearVelocity.Y > 30 then return end

                local hit = workspace:Raycast(torso.Position, Vector3.new(0, -TIP_GROUND_RANGE, 0), params)
                if not hit then return end

                local slope = Vector3.new(hit.Normal.X, 0, hit.Normal.Z)
                local lean = Vector3.new(up.X, 0, up.Z)
                local dir
                if slope.Magnitude > FLAT_SLOPE then
                    dir = slope.Unit
                elseif lean.Magnitude > 0.12 then
                    dir = lean.Unit
                else
                    dir = randomDir
                end

                local axis = Vector3.yAxis:Cross(dir)
                if axis.Magnitude < 1e-3 then return end
                axis = axis.Unit

                local ang = torso.AssemblyAngularVelocity
                if ang:Dot(axis) < TIP_MAX_SPIN then
                    local strength = 0.3 + 0.7 * up.Y
                    torso.AssemblyAngularVelocity = ang + axis * TIP_TORQUE * strength * dt
                end
            end))
        end
    end

    table.insert(ragConns, hum.StateChanged:Connect(function(_, new)
        if ragdolled and new ~= Enum.HumanoidStateType.Physics
            and new ~= Enum.HumanoidStateType.Dead then
            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end))

    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") then
            table.insert(ragConns, p.Touched:Connect(function(other)
                if not ragdolled or gettingUp then return end
                if not other.CanCollide or other:IsDescendantOf(char) then return end
                local speed = (p.AssemblyLinearVelocity - other.AssemblyLinearVelocity).Magnitude
                if speed < IMPACT_MIN_SPEED then return end
                if os.clock() - lastImpact < IMPACT_COOLDOWN then return end
                lastImpact = os.clock()
                playSound(SOUNDS_RAGDOLL, p)
                vfxImpact(p, other, speed, char)
            end))
        end
    end

    return true
end

local function disableRagdoll(instant)
    local char, hum, root = getChar()

    if camSubjectBackup then
        local cam = workspace.CurrentCamera
        if cam and hum and hum.Parent then cam.CameraSubject = hum end
        camSubjectBackup = nil
    end

    for _, c in ipairs(ragConns) do c:Disconnect() end
    table.clear(ragConns)

    for _, inst in ipairs(created) do
        if inst and inst.Parent then inst:Destroy() end
    end
    table.clear(created)

    local motorList = motors
    motors = {}

    local function finish()
        for p, v in pairs(collideBackup) do
            if p and p.Parent then p.CanCollide = v end
        end
        table.clear(collideBackup)
        for p, v in pairs(physBackup) do
            if p and p.Parent then p.CustomPhysicalProperties = v[1] end
        end
        table.clear(physBackup)
        if root and root.Parent then root.CanCollide = true end
        if hum and hum.Parent then
            hum.PlatformStand = false
            hum.AutoRotate = true
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        gettingUp = false
    end

    if instant or not (char and hum and root) then
        for _, m in ipairs(motorList) do
            if m and m.Parent then m.Enabled = true end
        end
        if root then
            local _, yaw = root.CFrame:ToEulerAnglesYXZ()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = CFrame.new(root.Position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, yaw, 0)
        end
        finish()
        return
    end

    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or root
    local faceUp = torso.CFrame.LookVector.Y > 0
    local head = Vector3.new(torso.CFrame.UpVector.X, 0, torso.CFrame.UpVector.Z)
    local yawCF
    if head.Magnitude > 0.2 then
        yawCF = CFrame.lookAt(Vector3.zero, faceUp and -head.Unit or head.Unit)
    else
        local _, yaw = root.CFrame:ToEulerAnglesYXZ()
        yawCF = CFrame.Angles(0, yaw, 0)
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}
    local origin = root.Position
    local hit = workspace:Raycast(origin, Vector3.new(0, -25, 0), params)
    local groundY = hit and hit.Position.Y or (origin.Y - 2.5)
    local r6Extra = (hum.RigType == Enum.HumanoidRigType.R6) and 2 or 0
    local standY = groundY + hum.HipHeight + root.Size.Y / 2 + r6Extra + 0.2

    local pitch = math.rad(faceUp and 90 or -90)
    local startCF = CFrame.new(origin.X, groundY + 1.1, origin.Z) * yawCF * CFrame.Angles(pitch, 0, 0)
    local endCF = CFrame.new(origin.X, standY, origin.Z) * yawCF

    local origC0, rnd = {}, {}
    for _, m in ipairs(motorList) do
        if m and m.Parent then
            origC0[m] = m.C0
            rnd[m] = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2
            m.Enabled = true
        end
    end

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = startCF

    playSound(SOUND_GETUP, root)

    task.spawn(function()
        local t0 = os.clock()
        while true do
            if not (root and root.Parent and hum and hum.Parent) then break end
            local a = math.clamp((os.clock() - t0) / GETUP_TIME, 0, 1)
            local e = 1 - (1 - a) ^ 3
            local k = math.rad(45) * (1 - e)

            root.CFrame = startCF:Lerp(endCF, e)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero

            for m, c0 in pairs(origC0) do
                if m.Parent then
                    local r = rnd[m]
                    m.C0 = c0 * CFrame.Angles(r.X * k, r.Y * k * 0.5, r.Z * k * 0.5)
                end
            end

            if a >= 1 then break end
            RunService.Heartbeat:Wait()
        end

        for m, c0 in pairs(origC0) do
            if m.Parent then m.C0 = c0 end
        end
        if root and root.Parent then root.CFrame = endCF end
        finish()
    end)
end

local lastJump = 0

local function ragdollJump()
    if not ragdolled or gettingUp then return end
    if os.clock() - lastJump < JUMP_COOLDOWN then return end

    local char, hum, root = getChar()
    if not (char and hum and root) then return end

    if JUMP_NEEDS_GROUND then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {char}
        local hit = workspace:Raycast(root.Position, Vector3.new(0, -4.5, 0), params)
        if not hit then return end
    end

    lastJump = os.clock()
    playSound(SOUND_JUMP, root)

    local v = root.AssemblyLinearVelocity
    local dir = hum.MoveDirection
    local launch = Vector3.new(
        v.X + dir.X * JUMP_PUSH,
        JUMP_POWER,
        v.Z + dir.Z * JUMP_PUSH
    )

    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") then
            p.AssemblyLinearVelocity = launch
        end
    end

    root.AssemblyAngularVelocity = Vector3.new(
        math.random(-4, 4), math.random(-2, 2), math.random(-4, 4)
    )
end

local COL_ON, COL_ON_DARK = Color3.fromRGB(86, 214, 120), Color3.fromRGB(38, 150, 80)
local COL_OFF, COL_OFF_DARK = Color3.fromRGB(255, 98, 98), Color3.fromRGB(186, 52, 66)

local function refreshUI()
    if not ui.main then return end
    local on = ragdolled
    local info = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenService:Create(ui.main, info, {BackgroundColor3 = on and COL_ON or COL_OFF}):Play()
    TweenService:Create(ui.shadow, info, {BackgroundColor3 = on and COL_ON_DARK or COL_OFF_DARK}):Play()
    ui.state.Text = on and "ON" or "OFF"

    if ui.lastState ~= on then
        ui.lastState = on
        ui.scale.Scale = 1.18
        ui.root.Rotation = on and -9 or 9
        TweenService:Create(ui.scale, TweenInfo.new(0.55, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(ui.root, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Rotation = 0}):Play()
    end
end

function setRagdoll(state)
    if state == ragdolled or gettingUp then return end
    if state then
        ragdolled = enableRagdoll()
    else
        ragdolled = false
        gettingUp = true
        disableRagdoll()
    end
    refreshUI()
end

local function buildGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "RagdollUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local parent
    pcall(function()
        if gethui then parent = gethui() end
    end)
    parent = parent or game:GetService("CoreGui")
    local ok = pcall(function() gui.Parent = parent end)
    if not ok then gui.Parent = player:WaitForChild("PlayerGui") end

    local OUTLINE = Color3.fromRGB(38, 32, 66)
    local SIZE, DEPTH = 88, 7

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromOffset(SIZE, SIZE + DEPTH)
    root.Position = UDim2.new(0.5, -SIZE / 2, 0.15, 0)
    root.BackgroundTransparency = 1
    root.Parent = gui
    local scale = Instance.new("UIScale", root)

    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.fromOffset(SIZE, SIZE)
    shadow.Position = UDim2.fromOffset(0, DEPTH)
    shadow.BackgroundColor3 = COL_OFF_DARK
    shadow.BorderSizePixel = 0
    shadow.Parent = root
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 18)
    local shadowStroke = Instance.new("UIStroke", shadow)
    shadowStroke.Color = OUTLINE
    shadowStroke.Thickness = 3

    local main = Instance.new("TextButton")
    main.Name = "Main"
    main.Size = UDim2.fromOffset(SIZE, SIZE)
    main.Position = UDim2.fromOffset(0, 0)
    main.BackgroundColor3 = COL_OFF
    main.BorderSizePixel = 0
    main.AutoButtonColor = false
    main.Text = ""
    main.Parent = root
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 18)
    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = OUTLINE
    mainStroke.Thickness = 3

    local shine = Instance.new("Frame")
    shine.Size = UDim2.new(1, -26, 0, 9)
    shine.Position = UDim2.fromOffset(13, 8)
    shine.BackgroundColor3 = Color3.new(1, 1, 1)
    shine.BackgroundTransparency = 0.72
    shine.BorderSizePixel = 0
    shine.Parent = main
    Instance.new("UICorner", shine).CornerRadius = UDim.new(1, 0)

    local function label(text, y, h, size, font)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, h)
        l.Position = UDim2.fromOffset(0, y)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.new(1, 1, 1)
        l.Font = font or Enum.Font.FredokaOne
        l.TextSize = size
        l.Parent = main
        local st = Instance.new("UIStroke", l)
        st.Color = OUTLINE
        st.Thickness = 2
        st.LineJoinMode = Enum.LineJoinMode.Round
        return l
    end

    label("RAGDOLL", 22, 14, 13)
    local state = label("OFF", 34, 32, 30)
    local hint = label("[" .. KEYBIND.Name .. "]", 66, 14, 11)
    hint.TextTransparency = 0.15

    local pressInfo = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local releaseInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local hoverInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function pressDown()
        TweenService:Create(main, pressInfo, {Position = UDim2.fromOffset(0, DEPTH - 2)}):Play()
    end
    local function pressUp()
        TweenService:Create(main, releaseInfo, {Position = UDim2.fromOffset(0, 0)}):Play()
    end

    main.MouseEnter:Connect(function()
        TweenService:Create(scale, hoverInfo, {Scale = 1.07}):Play()
    end)
    main.MouseLeave:Connect(function()
        TweenService:Create(scale, hoverInfo, {Scale = 1}):Play()
    end)

    local activeInput, dragStart, startPos, moved

    main.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            activeInput, dragStart, startPos, moved = i, i.Position, root.Position, false
            pressDown()
        end
    end)

    table.insert(connections, UIS.InputChanged:Connect(function(i)
        if not activeInput then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
            or (i.UserInputType == Enum.UserInputType.Touch and i == activeInput) then
            local d = i.Position - dragStart
            if not moved and d.Magnitude > 6 then
                moved = true
                pressUp()
            end
            if moved then
                root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end))

    table.insert(connections, UIS.InputEnded:Connect(function(i)
        if not activeInput then return end
        local isMouse = i.UserInputType == Enum.UserInputType.MouseButton1
            and activeInput.UserInputType == Enum.UserInputType.MouseButton1
        if isMouse or i == activeInput then
            local wasMoved = moved
            activeInput = nil
            if not wasMoved then
                pressUp()
                setRagdoll(not ragdolled)
            end
        end
    end))

    ui.gui, ui.root, ui.main, ui.shadow, ui.state, ui.scale = gui, root, main, shadow, state, scale
    ui.lastState = false
end

buildGui()

RunService:BindToRenderStep("RagdollFX", Enum.RenderPriority.Camera.Value + 1, vfxStep)

local persistent = {}

table.insert(persistent, UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == KEYBIND then
        setRagdoll(not ragdolled)
    end
end))

table.insert(persistent, UIS.JumpRequest:Connect(ragdollJump))

table.insert(persistent, player.CharacterAdded:Connect(function(char)
    ragdolled = false
    gettingUp = false
    camSubjectBackup = nil
    for _, c in ipairs(ragConns) do c:Disconnect() end
    table.clear(ragConns)
    table.clear(created); table.clear(motors); table.clear(collideBackup); table.clear(physBackup)
    refreshUI()
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        hum.Died:Connect(function()
            ragdolled = false
            refreshUI()
        end)
    end
end))

env.__RagdollCleanup = function()
    if ragdolled then pcall(disableRagdoll, true) end
    pcall(vfxCleanup)
    for _, c in ipairs(ragConns) do c:Disconnect() end
    for _, c in ipairs(persistent) do c:Disconnect() end
    for _, c in ipairs(connections) do c:Disconnect() end
    if ui.gui then ui.gui:Destroy() end
end
