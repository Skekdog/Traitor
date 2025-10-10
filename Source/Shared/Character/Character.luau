local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClimbLadder = require(ReplicatedStorage.Shared.Actions.ClimbLadder)
local Crouch = require(ReplicatedStorage.Shared.Actions.Crouch)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)
local JumpPower = require(script.Parent.JumpPower)
local LocalCharacter = require(script.Parent.LocalCharacter)
local WalkSpeed = require(script.Parent.WalkSpeed)

local clientServer = ReplicatedStorage.Remotes.ClientServer

local function initSnapToLadder(root: BasePart): ()
    root.Touched:Connect(function(part)
        if not part:HasTag("Ladder") then
            return
        end

        if Settings.GetSetting("Snap To Ladders") then
            ClimbLadder.Climb(part)
        end
    end)
end

local function registerCrouch(): ()
    ControlManager.Register("Crouch", function()
        Crouch.ToggleCrouching()
        return Enum.ContextActionResult.Pass
    end)
end

local function unregisterAll(): ()
    ControlManager.Unregister("Crouch")
end

LocalCharacter.Character:Connect(function(char)
    if not char then
        unregisterAll()
    end
end)

local function setHumanoidStates(hum: Humanoid): ()
    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
end

local function initRemoveDeathSound(root: BasePart): ()
    local death = root:FindFirstChild("Died")
    if death then
        death:Destroy()
    else
        local con
        con = root.ChildAdded:Connect(function(child)
            if child.Name == "Died" then
                con:Disconnect()
                child:Destroy()
            end
        end)
    end
end

local function initHeadTilt(char: Model): ()
    local neck = char:WaitForChild("Head"):WaitForChild("Neck")
    assert(neck:IsA("Motor6D"), "Neck is not a Motor6D")

    local camera = workspace.CurrentCamera

    local y = camera.CFrame:ToOrientation()
    while neck:IsDescendantOf(char) do
        task.wait(1 / 20)

        if not neck:IsDescendantOf(char) then
            break
        end

        local newY = camera.CFrame:ToOrientation()
        if newY == y then
            continue
        end

        y = newY
        clientServer.RotateHead:FireServer(y)
    end
end

LocalCharacter.Humanoid:Connect(function(hum)
    if not hum then
        return
    end

    WalkSpeed.Reset()
    JumpPower.Reset()

    setHumanoidStates(hum)

    local char = hum.Parent
    assert(char and char:IsA("Model"), "Humanoid has no Character")

    local root = char:WaitForChild("HumanoidRootPart")
    assert(root:IsA("BasePart"), "HumanoidRootPart is not a Part")

    registerCrouch()

    initSnapToLadder(root)
    initRemoveDeathSound(root)
    initHeadTilt(char)
end)

return nil