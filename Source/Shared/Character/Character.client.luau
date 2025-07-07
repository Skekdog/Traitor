local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClimbLadder = require(ReplicatedStorage.Shared.Actions.ClimbLadder)
local Crouch = require(ReplicatedStorage.Shared.Actions.Crouch)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)
local JumpPower = require(script.Parent.JumpPower)
local LocalCharacter = require(script.Parent.LocalCharacter)
local WalkSpeed = require(script.Parent.WalkSpeed)

local clientServer = ReplicatedStorage.Remotes.ClientServer

local function initSnapToLadder(root: BasePart): ()
    root.Touched:Connect(function(part)
        local map = LocalRoundInfo.Map()
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

local function registerCrouch(): ()
    ControlManager.Register("Crouch", function()
        Crouch.ToggleCrouching()
        return Enum.ContextActionResult.Sink
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

local function checkForWater(root: BasePart): boolean
    local map = LocalRoundInfo.Map()
    if not map then
        return false
    end

    for _, v in root:GetTouchingParts() do
        if v.Name == "! Water" or v.Name == "Water" then
            return true
        end
    end

    local params = RaycastParams.new()
    params.RespectCanCollide = false
    params.IgnoreWater = false
    params.FilterDescendantsInstances = {root.Parent :: Model}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(root.Position, Vector3.new(0, -5, 0), params)
    if not result then
        return false
    end

    return (result.Material == Enum.Material.Water) or ((result.Instance.Name == "! Water" or result.Instance.Name == "Water") and result.Instance:IsDescendantOf(map.DynamicMap))
end

local function initFallDamage(hum: Humanoid, root: BasePart): ()
    local startHeight = math.huge
    hum.StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Freefall then
            startHeight = root.Position.Y
        elseif state == Enum.HumanoidStateType.Landed then
            if checkForWater(root) then
                return
            end
            local distance = startHeight - root.Position.Y
            if distance > 15 then
                clientServer.Fell:FireServer(startHeight - root.Position.Y)
            end
            startHeight = math.huge
        elseif state == Enum.HumanoidStateType.Climbing then
            startHeight = math.huge
        end
    end)
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
    initFallDamage(hum, root)
    initRemoveDeathSound(root)
    initHeadTilt(char)
end)