local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AimWeaponClient = require(script.Parent.AimWeaponClient)
local ItemTypes = require(script.Parent.ItemsManager.ItemTypes)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)

local module = {}

local renderCon: RBXScriptConnection?

local recoilTarget = CFrame.new()
local recoil = CFrame.new()

function module.Show(item: ItemTypes.Item): ()
    if not item.Base.HoldAnimation then
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

    local viewmodel = (camera:FindFirstChild("Viewmodel") or ReplicatedStorage.Viewmodel:Clone()) :: typeof(ReplicatedStorage.Viewmodel)

    if not viewmodel.Parent then
        local shirt = char:FindFirstChildOfClass("Shirt")
        if shirt then
            shirt:Clone().Parent = viewmodel
        end

        local bodyColours = char:FindFirstChildOfClass("BodyColors")
        if bodyColours then
            bodyColours:Clone().Parent = viewmodel
        end
        
        viewmodel.Parent = camera
    else
        local model = viewmodel:FindFirstChild("Item")
        if model then
            model:Destroy()
        end

        for _, v in viewmodel.Humanoid.Animator:GetPlayingAnimationTracks() do
            v:Stop()
        end
    end

    local model = item.Base.Model:Clone()
    model.Name = "Item"

    local motor = Instance.new("Motor6D")
    motor.Part0 = viewmodel.RightHand
    motor.Part1 = model
    motor.Parent = model
    
    model.Anchored = false
    model.CanCollide = false
    model.CanTouch = false
    model.CanQuery = false

    model.Parent = viewmodel

    task.defer(function()
        viewmodel.UpperTorso.CanCollide = false
    end)

    module.PlayAnimation(item.Base.HoldAnimation)

    if renderCon then
        renderCon:Disconnect()
    end

    local bobbing = CFrame.new()
    renderCon = RunService.RenderStepped:Connect(function(dt: number)
        local breathing = CFrame.new(0, math.cos(os.clock() * 2) / 100, 0)
        local isMoving = hum.MoveDirection:Dot(hum.MoveDirection) > 0

        recoil = recoil:Lerp(recoilTarget, dt * 30)
        
        if isMoving then
            local bob = math.sin(os.clock() * 6) / 3
            bobbing = bobbing:Lerp(CFrame.new(bob, bob, bob), dt)
        else
            bobbing = bobbing:Lerp(CFrame.new(), dt)
        end

        local modifiers = breathing * bobbing * recoil

        camera.CFrame *= CFrame.Angles(math.rad(recoil.Y), math.rad(recoil.X), 0)

        local rotation = camera.CFrame * CFrame.Angles(math.rad(180), math.rad(180), math.rad(180))
        local final = modifiers * rotation * CFrame.new(0, -1.75, -0.75);
        (viewmodel.PrimaryPart :: BasePart).CFrame = final
    end)
end

function module.PlayAnimation(id: number): ()
    local viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel") :: typeof(ReplicatedStorage.Viewmodel)?
    if not viewmodel then
        return
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://"..id

    viewmodel.Humanoid.Animator:LoadAnimation(animation):Play()
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

LocalRoundInfo.Listen("PrimaryFire", function(item: ItemTypes.Weapon)
    if item.Kind == "Gun" then
        local x = item.Base.RecoilX / 4
        local y = item.Base.RecoilY / 4

        if AimWeaponClient.IsAiming then
            x /= 2
            y /= 2
        end

        recoilTarget *= CFrame.new(x, y, 0)
        
        task.delay(0.15, function()
            recoilTarget *= CFrame.new(-x, -y, 0)
        end)
    elseif item.Kind == "Melee" then
        module.PlayAnimation(item.Base.HitAnimation)
    end
end)

return module