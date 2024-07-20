local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ItemTypes = require(script.Parent.ItemsManager.ItemTypes)

local module = {}

local renderCon: RBXScriptConnection?

function module.Show(item: ItemTypes.Item): ()
    module.Hide()

    if not item.Base.HoldAnimation then
        return
    end

    local camera = workspace.CurrentCamera
    local char = Players.LocalPlayer.Character
    if not char then
        return
    end

    local viewmodel = ReplicatedStorage.Viewmodel:Clone()

    local shirt = char:FindFirstChildOfClass("Shirt")
    if shirt then
        shirt:Clone().Parent = viewmodel
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

    viewmodel.Parent = camera

    module.PlayAnimation(item.Base.HoldAnimation)

    renderCon = RunService.RenderStepped:Connect(function(dt)
        viewmodel.PrimaryPart.CFrame = camera.CFrame * CFrame.Angles(math.rad(180), math.rad(180), math.rad(180)) * CFrame.new(0, -1.75, -0.75)
    end)
end

function module.PlayAnimation(id: number): ()
    local viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel")
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

return module