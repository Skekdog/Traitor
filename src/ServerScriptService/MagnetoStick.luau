local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayAnimation = require(script.Parent.PlayAnimation)
local Types = require(ReplicatedFirst.RoundHandler.Types)

local module = {}

local controlledProps: {[number]: BasePart} = {}

local roundHandlerEvents = ReplicatedStorage:WaitForChild("RoundHandler")
local serverClient = ReplicatedStorage:WaitForChild("ServerClient")

local function stopControllingProp(prop: BasePart, userId: number)
    if not prop:IsDescendantOf(workspace) then
        return
    end
    local alignPos = prop:FindFirstChildOfClass("AlignPosition") :: AlignPosition
    local activeHolder = prop:FindFirstChild("ActiveHolder") :: NumberValue

    alignPos.Attachment1 = nil
    alignPos.Enabled = false
    activeHolder.Value = 0

    local lastHolder = prop:FindFirstChild("LastHolder") :: NumberValue
    local con: RBXScriptConnection
    local resetHolderThread = task.delay(5, function()
        if con.Connected then
            con:Disconnect()
        end
        if not prop:IsDescendantOf(workspace) then
            return
        end
        prop:SetNetworkOwnershipAuto()
        lastHolder.Value = 0
    end)

    lastHolder.Value = userId

    con = lastHolder.Changed:Once(function(newId)
        task.cancel(resetHolderThread)
    end)

    local plr = Players:GetPlayerByUserId(userId)
    if plr then
        PlayAnimation(plr, 13269497293, "MagnetoAnimation")
        serverClient.PlayViewmodelAnimation:FireClient(plr, 13269497293)
    end

    controlledProps[userId] = nil
end

local function getPropByRay(participant: Types.Participant, ray: Ray): (BasePart?, Vector3?)
    local char = participant.Character

    local head = char:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end

    local root = char.PrimaryPart
    if not root then
        return
    end

    local map = roundHandlerEvents.MapFolder.Value
    if not map then
        return
    end

    local props = map:FindFirstChild("Props")
    local weaponSpawns = map:FindFirstChild("WeaponSpawns")
    if not props and not weaponSpawns then
        return
    end

    local rayParams = RaycastParams.new()
    rayParams.IgnoreWater = true
    rayParams.RespectCanCollide = false
    rayParams.CollisionGroup = "Raycasts"
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = {workspace.Corpses, props, weaponSpawns}

    local result = workspace:Raycast(head.Position, ray.Direction * 10, rayParams)
    if not result then
        return
    end

    return result.Instance, result.Position
end

function module.AlternateFire(participant: Types.Participant, cameraRayInfo: Ray)
    local userId = participant.Player.UserId
    local alreadyControlled = controlledProps[userId]
    if alreadyControlled then
        if alreadyControlled.Parent then
            stopControllingProp(alreadyControlled, userId)
        else
            controlledProps[userId] = nil
        end
    end

    local object = getPropByRay(participant, cameraRayInfo)
    if not object then
        return
    end

    local map = roundHandlerEvents.MapFolder.Value
    if not map then
        return
    end

    local props = map:FindFirstChild("Props")
    local weaponSpawns = map:FindFirstChild("WeaponSpawns")

    local model = object:FindFirstAncestorOfClass("Model")

    if (props and not props:IsAncestorOf(object)) and (weaponSpawns and not weaponSpawns:IsAncestorOf(object)) and (model and not model:IsDescendantOf(workspace.Corpses)) then
        return
    end

    if object:GetAttribute("NoGrab") then
        return
    end

    if alreadyControlled == object then
        return
    end

    if object.AssemblyMass == math.huge then -- anchored props have inf assemblymass
        return
    end

    local biggestPlane = math.max(object.Size.X, object.Size.Y, object.Size.Z)
    if (object.AssemblyMass > 160) or (object.Size.X * object.Size.Y * object.Size.Z > 50) or (biggestPlane > 5) then -- Mostly arbitrarily chosen by looking at Skyscraper and Mesa Monocraft props
        return
    end

    local alignPos = object:FindFirstChildOfClass("AlignPosition") or Instance.new("AlignPosition")
    if not alignPos.Parent then
        alignPos.Responsiveness = 200
        alignPos.MaxVelocity = 40
        alignPos.MaxForce = 10000 * (object.AssemblyMass / 20) -- 20 is the mass of a Mesa Monocraft barrel
        alignPos.ApplyAtCenterOfMass = true
        alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment

        local attachPoint = Instance.new("Attachment")
        attachPoint.Name = "AttachPoint"

        alignPos.Attachment0 = attachPoint

        attachPoint.Parent = object
        alignPos.Parent = object
    end

    PlayAnimation(participant.Player, 13269497293, "MagnetoAnimation")
    serverClient.PlayViewmodelAnimation:FireClient(participant.Player, 13269497293)

    local activeHolder = object:FindFirstChild("ActiveHolder") :: NumberValue or Instance.new("NumberValue")
    if activeHolder.Parent and Players:GetPlayerByUserId(activeHolder.Value) then
        if activeHolder.Value == userId then
            stopControllingProp(object, userId)
        end
        return
    elseif not activeHolder.Parent then
        activeHolder.Name = "ActiveHolder"
        activeHolder.Parent = object
    end

    activeHolder.Value = userId

    local lastHolder = object:FindFirstChild("LastHolder") :: NumberValue or Instance.new("NumberValue")
    if not lastHolder.Parent then
        lastHolder.Name = "LastHolder"
        lastHolder.Parent = object
    end

    local head = participant.Character:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end

    controlledProps[userId] = object
    object:SetNetworkOwner(participant.Player)
    alignPos.Attachment1 = head:FindFirstChild("MagnetoAttachment") :: Attachment?
    alignPos.Enabled = true
end

function module.PrimaryFire(participant: Types.Participant, cameraRayInfo: Ray)
    local object, position = getPropByRay(participant, cameraRayInfo)
    if not object or not position then
        return
    end

    local activeHolder = object:FindFirstChild("ActiveHolder") :: NumberValue?
    if activeHolder and Players:GetPlayerByUserId(activeHolder.Value) then
        return
    end
    
    object:SetNetworkOwner()
    object:ApplyImpulseAtPosition(participant.Character:GetPivot().LookVector * 50 * (object.AssemblyMass / 20), position)
end

function module.OnUnequip(plr: Player): ()
    local userId = plr.UserId
    local prop = controlledProps[userId]
    if prop then
        stopControllingProp(prop, userId)
    end
end

task.spawn(function()
    while true do
        for userId, prop in controlledProps do
            local plr = Players:GetPlayerByUserId(userId)
            if not plr then
                stopControllingProp(prop, userId)
                continue
            end
            
            local distance = plr:DistanceFromCharacter(prop.Position)
            if distance == 0 or distance > 20 then
                stopControllingProp(prop, userId)
                continue
            end

            for _, v in prop:GetTouchingParts() do
                if v:FindFirstAncestorOfClass("Model") == plr.Character then
                    stopControllingProp(prop, userId)
                    continue
                end
            end
        end
        task.wait()
    end
end)

return module
