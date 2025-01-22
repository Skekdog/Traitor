local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.RoundRule.Types)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local spring = require(script.Parent.spring)

local module = {}

local renderCon: RBXScriptConnection?

local cameraRecoilSpring = spring.new(20, 0.8)
local armRecoilSpring = spring.new(20, 0.8)
local breathingSpring = spring.new(1, 10)
local bobbingSpring = spring.new(10, 1)

module.ReloadSpring = spring.new(7, 0.8)

type Viewmodel = typeof(ReplicatedStorage.Viewmodel)
local function laser(viewmodel: Viewmodel, gun: Types.GunWeaponDefinition): ()
    if not gun.LaserColor then
        return
    end

    local item = viewmodel:FindFirstChild("Item")
    if not item or not item:IsA("BasePart") then
        return
    end

    local attachment = item:FindFirstChild("LaserAttachment", true)
    if not attachment or not attachment:IsA("Attachment") then
        return
    end

    local laser = item:FindFirstChild("Laser") :: typeof(ReplicatedStorage.Laser)?
    local ball = item:FindFirstChild("Ball") :: Part?

    if not ball then
        ball = Instance.new("Part")
        assert(ball)

        ball.Anchored = true
        ball.Shape = Enum.PartType.Ball
        ball.Size = Vector3.one * 1.75

        ball.CastShadow = false
        ball.Transparency = 0.2
        ball.Material = Enum.Material.Neon
        ball.Color = gun.LaserColor

        ball.CanCollide = false
        ball.CanTouch = false
        ball.CanQuery = false
        
        ball.TopSurface = Enum.SurfaceType.Smooth
        ball.BottomSurface = Enum.SurfaceType.Smooth
        ball.LeftSurface = Enum.SurfaceType.Smooth
        ball.RightSurface = Enum.SurfaceType.Smooth
        ball.FrontSurface = Enum.SurfaceType.Smooth
        ball.BackSurface = Enum.SurfaceType.Smooth

        ball.Name = "Ball"
        ball.Parent = item
    end
    assert(ball)

    if not laser then
        laser = ReplicatedStorage.Laser:Clone()
        assert(laser)

        laser.Color = gun.LaserColor
        laser.Material = Enum.Material.Neon

        laser.Parent = item
    end

    assert(laser)

    local camera = workspace.CurrentCamera
    local direction = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2, 1).Direction * 10000

    local rayParams = RaycastParams.new()
    local map = LocalRoundInfo.GetMap()
    if map then
        rayParams:AddToFilter(map.Bounds)
    end
    rayParams.FilterDescendantsInstances = {viewmodel}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(attachment.WorldPosition, direction, rayParams)

    local distance = if result then result.Distance else 10000
    local half = distance / 2

    laser.Mesh.Scale = Vector3.new(0.2, half, 0.2)

    laser.PivotOffset = CFrame.new(0, -half, 0)
    laser:PivotTo(CFrame.lookAlong(attachment.WorldPosition, direction) * CFrame.Angles(math.rad(-90), 0, 0))

    ball.Position = if result then result.Position else Vector3.new()
end

function module.Show(item: Types.AnyItemDefinition): ()
    if not item.HoldAnimation or not item.Model then
        module.Hide()
        return
    end

    local camera = workspace.CurrentCamera
    local char = Players.LocalPlayer.Character
    if not char then
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end

    local viewmodel = (camera:FindFirstChild("Viewmodel") or ReplicatedStorage.Viewmodel:Clone()) :: Viewmodel

    if not viewmodel.Parent then
        local shirt = char:FindFirstChildOfClass("Shirt")
        if shirt then
            shirt:Clone().Parent = viewmodel
        end

        local bodyColours = char:FindFirstChildOfClass("BodyColors")
        if bodyColours then
            bodyColours:Clone().Parent = viewmodel
        end
        
        viewmodel.Parent = camera :: any
    else
        local model = viewmodel:FindFirstChild("Item")
        if model then
            model:Destroy()
        end

        for _, v in viewmodel.Humanoid.Animator:GetPlayingAnimationTracks() do
            v:Stop()
        end
    end

    local model = item.Model:Clone()
    model.Name = "Item"

    local motor = Instance.new("Motor6D")
    motor.Part0 = viewmodel.RightHand
    motor.Part1 = model

    local c1 = item.Model:GetAttribute("AnimC1")
    if typeof(c1) == "CFrame" then
        motor.C1 = c1
    end

    motor.Parent = model

    local function configure(part: BasePart): ()
        part.Anchored = false
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Massless = true
    end
    
    configure(model)
    for _, v in model:GetDescendants() do
        if v:IsA("BasePart") then
            configure(v)
        end
    end

    model.Parent = viewmodel

    task.defer(function()
        viewmodel.UpperTorso.CanCollide = false
    end)

    module.PlayAnimation(item.HoldAnimation)

    if renderCon then
        renderCon:Disconnect()
    end

    renderCon = RunService.RenderStepped:Connect(function(dt: number)
        local timeNow = os.clock()

        breathingSpring.target = Vector3.new(math.cos(timeNow) / 2, math.cos(timeNow), math.cos(timeNow) / 2) / 5
        breathingSpring:update(dt)

        cameraRecoilSpring:update(1 / 60)
        armRecoilSpring:update(1 / 60)

        local isMoving = hum.MoveDirection:Dot(hum.MoveDirection) > 0
        
        if isMoving then
            bobbingSpring.target = Vector3.new(math.sin(timeNow * 7) * 0.1, math.sin(timeNow * 10) * 0.1, 0)
        else
            bobbingSpring.target = Vector3.zero
        end

        bobbingSpring:update(dt)
        module.ReloadSpring:update(dt)

        local modifiers = breathingSpring.p + bobbingSpring.p + armRecoilSpring.p

        local r = cameraRecoilSpring.p
        camera.CFrame *= CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))

        local rotation = camera.CFrame * CFrame.Angles(math.rad(180), math.rad(180), math.rad(180))
        local final = CFrame.new(modifiers) * rotation * CFrame.new(0, -1.75, -0.75);
        (viewmodel.PrimaryPart :: BasePart).CFrame = final

        if item.Kind == "Gun" then
            laser(viewmodel, item)
        end
    end)
end

function module.PlayAnimation(uri: string, name: string?): ()
    local viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel") :: Viewmodel?
    if not viewmodel then
        return
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = uri

    local track = viewmodel.Humanoid.Animator:LoadAnimation(animation)
    track.Name = name or ""
    track:Play()
end

function module.StopAnimation(name: string): ()
    local viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel") :: Viewmodel?
    if not viewmodel then
        return
    end

    for _, v in viewmodel.Humanoid.Animator:GetPlayingAnimationTracks() do
        if v.Name == name then
            v:Stop()
        end
    end
end

function module.Hide(): ()
    local viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel")
    if viewmodel then
        viewmodel:Destroy()
    end

    if renderCon then
        renderCon:Disconnect()
    end
end

return module