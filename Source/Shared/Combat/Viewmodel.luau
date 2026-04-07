local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VRService = game:GetService("VRService")
local Raycasts = require(ReplicatedStorage.API.Item.Behaviour.Raycasts)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local Types = require(ReplicatedStorage.API.Types)
local spring = require(ReplicatedStorage.Shared.Util.spring)
local MuzzleFlash = require(script.Parent.MuzzleFlash)

local module = {}

local renderCon: RBXScriptConnection?

local cameraRecoilSpring = spring.new(20, 0.8)
local armRecoilSpring = spring.new(20, 0.8)
local breathingSpring = spring.new(1, 10)
local bobbingSpring = spring.new(10, 1)

module.ReloadSpring = spring.new(7, 0.8)

local isAiming = false
function module.SetIsAiming(is: boolean): ()
    isAiming = is
end

local shirtCon: RBXScriptConnection?
local coloursCon: RBXScriptConnection?
local childCon: RBXScriptConnection?

local isTempHidden = false

local function clearViewmodelAppearanceConnections(): ()
    if shirtCon then
        shirtCon:Disconnect()
        shirtCon = nil
    end
    if coloursCon then
        coloursCon:Disconnect()
        coloursCon = nil
    end
    if childCon then
        childCon:Disconnect()
        childCon = nil
    end
end

type Viewmodel = typeof(ReplicatedStorage.Assets.Viewmodel)
local function laser(viewmodel: Viewmodel, item: Types.Item): ()
    if not item.LaserColor then
        return
    end

    local char = LocalCharacter.Character()
    if not char then
        return
    end

    local itemModel = viewmodel:FindFirstChild("Item")
    if not itemModel or not itemModel:IsA("BasePart") then
        return
    end

    local attachment = itemModel:FindFirstChild("LaserAttachment", true)
    assert(attachment and attachment:IsA("Attachment"), "Missing laser attachment")

    local laser = itemModel:FindFirstChild("Laser") :: typeof(ReplicatedStorage.Assets.Laser)?
    local ball = itemModel:FindFirstChild("Ball") :: Part?

    if not ball then
        ball = Instance.new("Part")
        assert(ball)

        ball.Anchored = true
        ball.Shape = Enum.PartType.Ball
        ball.Size = Vector3.one * 1.75

        ball.CastShadow = false
        ball.Transparency = 0.2
        ball.Material = Enum.Material.Neon

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
        ball.Parent = itemModel
    end
    assert(ball)

    ball.Color = item.LaserColor

    if not laser then
        laser = ReplicatedStorage.Assets.Laser:Clone()
        assert(laser)

        laser.Material = Enum.Material.Neon

        laser.Parent = itemModel
    end

    assert(laser)

    laser.Color = item.LaserColor

    local position = Raycasts.Hitscan(Raycasts.GetDefaultRaycastParams(char), workspace.CurrentCamera.CFrame.Position, Raycasts.GetDirection(), item.MaxDistance or 10000).Position

    CreateEmptyPart(attachment.CFrame).Color = Color3.fromRGB(255,255,255)

    local distance = (attachment.WorldPosition - position).Magnitude
    local half = distance / 2

    laser.Mesh.Scale = Vector3.new(0.05, half, 0.05)

    laser.CFrame = CFrame.lookAt((attachment.WorldPosition + position) / 2, position) * CFrame.Angles(math.rad(-90), 0, 0)

    ball.Position = position
end

local function tempHideViewmodel(): ()
    isTempHidden = true

    local viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel") :: Viewmodel?
    if not viewmodel then
        return
    end

    for _, part in viewmodel:GetDescendants() do
        if part:IsA("BasePart") then
            part:SetAttribute("OriginalTransparency", part.Transparency)
            part.Transparency = 1
        end
    end
end

local function tempShowViewmodel(): ()
    isTempHidden = false

    local viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel") :: Viewmodel?
    if not viewmodel then
        return
    end

    for _, part in viewmodel:GetDescendants() do
        if part:IsA("BasePart") then
            local originalTransparency = part:GetAttribute("OriginalTransparency")
            if typeof(originalTransparency) == "number" then
                part.Transparency = originalTransparency
            end
        end
    end
end

function module.Show(item: Types.Item): ()
    clearViewmodelAppearanceConnections()

    if not item.HoldAnimation or not item.Model or VRService.VREnabled then
        module.Hide()
        return
    end

    local camera = workspace.CurrentCamera
    local char = LocalCharacter.Character()
    if not char then
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end

    local viewmodel = (camera:FindFirstChild("Viewmodel") or ReplicatedStorage.Assets.Viewmodel:Clone()) :: Viewmodel

    if not viewmodel.Parent then
        local function updateShirt(shirt: Shirt): ()
            local oldShirt = viewmodel:FindFirstChildOfClass("Shirt")
            if oldShirt then
                oldShirt:Destroy()
            end

            local newShirt = shirt:Clone()
            newShirt.Parent = viewmodel

            if shirtCon then
                shirtCon:Disconnect()
            end

            shirtCon = shirt.Changed:Connect(function(prop)
                if prop == "Parent" then
                    return
                end
                (newShirt :: any)[prop] = (shirt :: any)[prop]
            end)
        end

        local function updateColours(colours: BodyColors): ()
            local oldColours = viewmodel:FindFirstChildOfClass("BodyColors")
            if oldColours then
                oldColours:Destroy()
            end

            local newColours = colours:Clone()
            newColours.Parent = viewmodel

            if coloursCon then
                coloursCon:Disconnect()
            end

            coloursCon = colours.Changed:Connect(function(prop)
                if prop == "Parent" then
                    return
                end
                (newColours :: any)[prop] = (colours :: any)[prop]
            end)
        end

        local shirt = char:FindFirstChildOfClass("Shirt")
        if shirt then
            updateShirt(shirt)
        end

        local bodyColours = char:FindFirstChildOfClass("BodyColors")
        if bodyColours then
            updateColours(bodyColours)
        end

        childCon = char.ChildAdded:Connect(function(child)
            if child:IsA("Shirt") then
                updateShirt(child)
            elseif child:IsA("BodyColors") then
                updateColours(child)
            end
        end)

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

    local model = item.Model:Clone();
    (model :: PVInstance).Name = "Item"

    ForEachPart(model, function(part)
        part.Massless = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
    end)

    local motor = Instance.new("Motor6D")
    motor.Part0 = viewmodel.RightHand
    motor.Part1 = GetPrimaryPart(model)

    local c1 = item.Model:GetAttribute("AnimC1")
    if typeof(c1) == "CFrame" then
        motor.C1 = c1
    end

    motor.Parent = model;

    (model :: PVInstance).Parent = viewmodel

    task.defer(function()
        viewmodel.UpperTorso.CanCollide = false
    end)

    module.PlayAnimation(item.HoldAnimation)

    if renderCon then
        renderCon:Disconnect()
    end

    renderCon = RunService.PreRender:Connect(function(dt: number)
        local timeNow = os.clock()

        breathingSpring.target = Vector3.new(math.cos(timeNow) / 2, math.cos(timeNow), math.cos(timeNow) / 2) / 5
        breathingSpring:update(dt)

        cameraRecoilSpring:update(dt)
        armRecoilSpring:update(dt)

        local isMoving = hum.MoveDirection.Magnitude > 0

        if isMoving then
            local speedModifier = hum.WalkSpeed / 16
            bobbingSpring.target = Vector3.new(math.sin(timeNow * 7 * speedModifier) * 0.1, math.sin(timeNow * 10 * speedModifier) * 0.1, 0) * speedModifier
        else
            bobbingSpring.target = Vector3.zero
        end

        bobbingSpring:update(dt)
        module.ReloadSpring:update(dt)

        local modifiers = breathingSpring.p + bobbingSpring.p + armRecoilSpring.p + module.ReloadSpring.p

        local r = cameraRecoilSpring.p * (dt * 60) -- i'm not certain why this is needed, but otherwise recoil is dependent on fps. 😃
        camera.CFrame *= CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))

        local final = camera.CFrame:ToWorldSpace(CFrame.new(modifiers) * CFrame.new(0, -1.75, -0.75));

        if not viewmodel.PrimaryPart then
            return
        end
        (viewmodel.PrimaryPart :: BasePart).CFrame = final

        laser(viewmodel, item)
    end)

    if isTempHidden then
        tempHideViewmodel()
    end
end

Players.LocalPlayer:GetPropertyChangedSignal("CameraMode"):Connect(function()
    if Players.LocalPlayer.CameraMode == Enum.CameraMode.Classic then
        tempHideViewmodel()
    else
        tempShowViewmodel()
    end
end)

function module.PlayAnimation(content: Content, name: string?): AnimationTrack?
    local viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel") :: Viewmodel?
    if not viewmodel then
        return nil
    end

    if not content.Uri then
        return
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = content.Uri

    local track = viewmodel.Humanoid.Animator:LoadAnimation(animation)
    track.Name = name or ""
    track:Play()

    return track
end

function module.StopAnimation(name: string): ()
    local viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel") :: Viewmodel?
    if not viewmodel then
        return
    end

    for _, v in viewmodel.Humanoid.Animator:GetPlayingAnimationTracks() do
        if v.Name == name then
            -- Otherwise Animation tracks remain loaded :/
            v.Ended:Once(function()
                v:Destroy()
            end)
            v:Stop()
        end
    end
end

function module.Hide(): ()
    clearViewmodelAppearanceConnections()
    local viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel")
    if viewmodel then
        viewmodel:Destroy()
    end

    if renderCon then
        renderCon:Disconnect()
    end
end

function module.Recoil(item: Types.Item): ()
    local x = if item.RecoilX then item.RecoilX / 4 else 0
    local y = if item.RecoilY then item.RecoilY / 4 else 0

    if isAiming then
        x /= 2
        y /= 2
    end

    cameraRecoilSpring.p = Vector3.new(y, x, x + y)
    armRecoilSpring.p = Vector3.new(x, y, 0)
end

function module.GetViewmodelItem(): Types.MapObject?
    local viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel") :: Viewmodel?
    if not viewmodel then
        return nil
    end

    local item = viewmodel:FindFirstChild("Item")
    if not item or (not item:IsA("BasePart") and not item:IsA("Model")) then
        return nil
    end

    return item :: Types.MapObject
end

function module.MuzzleFlash(): ()
    local item = module.GetViewmodelItem()
    if item then
        MuzzleFlash(item)
    end
end

return table.freeze(module)