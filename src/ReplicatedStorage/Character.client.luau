local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(ReplicatedStorage.Settings.Settings)
local ClimbLadder = require(script.Parent.ClimbLadder)
local ControlManager = require(script.Parent.ControlManager)
local Crouch = require(script.Parent.Crouch)
local JumpPower = require(script.Parent.JumpPower)
local LocalCharacter = require(script.Parent.LocalCharacter)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local WalkSpeed = require(script.Parent.WalkSpeed)

local clientServer = ReplicatedStorage:WaitForChild("ClientServer")

local function initSnapToLadder(root: BasePart): ()
    root.Touched:Connect(function(part)
        local map = LocalRoundInfo.GetMap()
        if not map then
            return
        end

        if part.Name ~= "Ladder" or not part:IsDescendantOf(map.Bounds) then
            return
        end
        
        if Settings.GetSetting("Snap To Ladders") and ClimbLadder.SnapCooldown < os.clock() then
            ClimbLadder.SnapCooldown = os.clock() + 3
            ClimbLadder.Climb(part)
        end
    end)
end

local function registerClimbLadder(root: BasePart): ()
    ControlManager.Register("Climb Ladder", true, function()
        local root = LocalCharacter.GetRootPart()
        if not root then
            return Enum.ContextActionResult.Pass
        end
    
        local map = LocalRoundInfo.GetMap()
        if not map then
            return Enum.ContextActionResult.Pass
        end
    
        local bounds = map.Bounds
        if not bounds then
            return Enum.ContextActionResult.Pass
        end
    
        for _, v in root:GetTouchingParts() do
            if v.Name == "Ladder" and v:IsDescendantOf(bounds) then
                ClimbLadder.Climb(v)
                return Enum.ContextActionResult.Sink
            end
        end
    
        return Enum.ContextActionResult.Pass
    end)
end

local function registerCrouch(): ()
    ControlManager.Register("Crouch", true, function()
        Crouch.ToggleCrouching()
        return Enum.ContextActionResult.Sink
    end)
end

local function unregisterAll(): ()
    ControlManager.Unregister("Climb Ladder")
    ControlManager.Unregister("Crouch")
end

LocalCharacter.CharacterRemoving:Connect(unregisterAll)

LocalCharacter.HumanoidAdded:Connect(function(hum)
    WalkSpeed.Reset()
    JumpPower.Reset()

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

    local char = hum.Parent
    assert(char, "Humanoid has no Character")

    local root = char:WaitForChild("HumanoidRootPart")
    assert(root:IsA("BasePart"), "HumanoidRootPart is not a Part")

    registerClimbLadder(root)
    registerCrouch()

    initSnapToLadder(root)

    local startHeight = math.huge
    hum.StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Freefall then
            startHeight = root.Position.Y
        elseif state == Enum.HumanoidStateType.Landed then
            local distance = startHeight - root.Position.Y
            if distance > 15 then
                clientServer.Fell:FireServer(startHeight - root.Position.Y)
            end
            startHeight = math.huge
        elseif state == Enum.HumanoidStateType.Climbing then
            startHeight = math.huge
        end
    end)

    local neck = char:WaitForChild("Head"):WaitForChild("Neck")
    assert(neck:IsA("Motor6D"), "Neck is not a Motor6D")

    local camera = workspace.CurrentCamera

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

    local y = camera.CFrame:ToOrientation()
    while neck:IsDescendantOf(char) do
        task.wait(1 / 20)

        if not neck then
            break
        end

        local newY = camera.CFrame:ToOrientation()
        if newY == y then
            continue
        end

        y = newY
        clientServer.RotateHead:FireServer(y)
    end
end)