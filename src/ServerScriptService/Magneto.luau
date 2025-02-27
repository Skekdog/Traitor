local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.RoundRule.Types)

local module = {}

local controlledProps: {[number]: BasePart} = {}

local serverClient = ReplicatedStorage:WaitForChild("ServerClient")

local function stopControllingProp(prop: BasePart, userId: number, stoppedHoldingStick: boolean?)
    local plr = Players:GetPlayerByUserId(userId)
    if plr then
        --ReplicatedStorage.ServerClient.SetMagnetoHintForCorpse:FireClient(plr, false)
    end

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

        local primaryPart = if prop:IsA("Model") then prop.PrimaryPart :: BasePart else prop
        primaryPart:SetNetworkOwnershipAuto()
        lastHolder.Value = 0
    end)

    lastHolder.Value = userId

    con = lastHolder.Changed:Once(function(newId)
        task.cancel(resetHolderThread)
    end)

    if plr and not stoppedHoldingStick then
        serverClient.PlayViewmodelAnimation:FireClient(plr, 13269497293)
    end

    controlledProps[userId] = nil
end

local function getPropByRay(participant: Types.Participant, direction: Vector3): (BasePart?, Vector3?, boolean?)
    local char = participant:GetCharacter()
	if not char then
		return
	end

    local head = char:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end

    local root = char.PrimaryPart
    if not root then
        return
    end

    local map = participant.Round:GetMap()

    local props = map.Props
    local itemSpawns = map.ItemSpawns
	local ammoSpawns = map.AmmoSpawns

    local rayParams = RaycastParams.new()
    rayParams.IgnoreWater = true
    rayParams.RespectCanCollide = false
    rayParams.CollisionGroup = "Raycasts"
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = {workspace.Corpses, props, itemSpawns, ammoSpawns}

    local result = workspace:Raycast(head.Position, direction * 10, rayParams)
    if not result then
        return
    end

    local object = result.Instance :: BasePart
    local model = object:FindFirstAncestorOfClass("Model")

    local isCorpse = model and model:IsDescendantOf(workspace.Corpses)

    if (props and not props:IsAncestorOf(object)) and (itemSpawns and not itemSpawns:IsAncestorOf(object)) and (not isCorpse) then
        return
    end

    if object.AssemblyMass == math.huge then -- anchored props have inf assemblymass
        return
    end

    return object, result.Position, isCorpse
end

function module.AlternateFire(item: Types.Item, participant: Types.Participant, direction: Vector3)
    local userId = participant.Player.UserId
    local alreadyControlled = controlledProps[userId]
    if alreadyControlled then
        if alreadyControlled.Parent then
            stopControllingProp(alreadyControlled, userId)
        else
            controlledProps[userId] = nil
        end
    end

    local object, _, isCorpse = getPropByRay(participant, direction)
    if not object then
        return
    end

    if object:GetAttribute("NoGrab") then
        return
    end

    if alreadyControlled == object then
        return
    end

    local size = if object:IsA("Model") then object:GetExtentsSize() else object.Size
    local biggestPlane = math.max(size.X, size.Y, size.Z)

    local primaryPart = if object:IsA("Model") then object.PrimaryPart else object
    assert(primaryPart)

    local mass = primaryPart.AssemblyMass

    if (not isCorpse) and ((mass > 160) or (size.X * size.Y * size.Z > 50) or (biggestPlane > 5)) then -- Mostly arbitrarily chosen by looking at Skyscraper and Mesa Monocraft props
        return
    end

    -- AssemblyMass is incorrect for corpses, unsure why
    if isCorpse and object.Parent then
        mass = 0
        for _, descendant in object.Parent:GetDescendants() do
            if descendant:IsA("BasePart") then
                mass += descendant.Mass
            end
        end
    end

    if isCorpse then
       -- ReplicatedStorage.ServerClient.SetMagnetoHintForCorpse:FireClient(participant.Player, true)
    end

    local alignPos = object:FindFirstChildOfClass("AlignPosition") or Instance.new("AlignPosition")
    if not alignPos.Parent then
        alignPos.Responsiveness = 200
        alignPos.MaxVelocity = 40
        alignPos.MaxForce = 10000 * (mass / 20) -- 20 is the mass of a Mesa Monocraft barrel
        alignPos.ApplyAtCenterOfMass = true
        alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment

        local attachPoint = Instance.new("Attachment")
        attachPoint.Name = "AttachPoint"

        alignPos.Attachment0 = attachPoint

        attachPoint.Parent = primaryPart
        alignPos.Parent = object
    end

    participant:TryPlayAnimation(13269497293, "MagnetoAnimation")
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

	local char = participant:GetCharacter()
	if not char then
		return
	end

    local head = char:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end

    controlledProps[userId] = object
    primaryPart:SetNetworkOwner(participant.Player)
    alignPos.Attachment1 = head:FindFirstChild("MagnetoAttachment") :: Attachment?

    if not alignPos.Attachment1 then
        local magnetoAttachment = Instance.new("Attachment")
        magnetoAttachment.Name = "MagnetoAttachment"
        magnetoAttachment.CFrame = CFrame.new(0, 0, -6)
        magnetoAttachment.Parent = head
        alignPos.Attachment1 = magnetoAttachment
    end
    
    alignPos.Enabled = true
end

function module.PrimaryFire(item: Types.Item, participant: Types.Participant, direction: Vector3)
	local char = participant:GetCharacter()
	if not char then
		return
	end

	local head = char:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end

    local controlledProp = controlledProps[participant.Player.UserId]
    if controlledProp and controlledProp:IsA("BasePart") and controlledProp:IsDescendantOf(workspace.Corpses) then
        local rope = controlledProp:FindFirstChildOfClass("RopeConstraint") or Instance.new("RopeConstraint")
        rope.Attachment0 = controlledProp:FindFirstChildOfClass("Attachment") or Instance.new("Attachment")

        if rope.Attachment1 then
            rope.Attachment1:Destroy()
        end

        local params = RaycastParams.new()
        params.CollisionGroup = "Raycasts"
        params.FilterDescendantsInstances = {participant.Round:GetMap().StaticMap}
        params.FilterType = Enum.RaycastFilterType.Include
        local result = workspace:Raycast(head.Position, direction * 10, params)
        if result and (controlledProp.Position - result.Position).Magnitude < 6 then
            local attachment = Instance.new("Attachment")
            assert(result.Instance:IsA("BasePart") or result.Instance:IsA("Terrain"))
            attachment.CFrame = result.Instance.CFrame:ToObjectSpace(CFrame.new(result.Position))
            attachment.Parent = result.Instance
            
            rope.Attachment1 = attachment
            rope.Visible = true
            rope.Length = (result.Position - controlledProp.Position).Magnitude
            rope.Parent = controlledProp
            stopControllingProp(controlledProp, participant.Player.UserId)
        end
        return
    end

    local object, position = getPropByRay(participant, direction)
    if not object or not position then
        return
    end

    local activeHolder = object:FindFirstChild("ActiveHolder") :: NumberValue?
    if activeHolder and Players:GetPlayerByUserId(activeHolder.Value) then
        return
    end

    local primaryPart = if object:IsA("Model") then object.PrimaryPart else object
    assert(primaryPart)
    
    primaryPart:SetNetworkOwner()
    primaryPart:ApplyImpulseAtPosition(char:GetPivot().LookVector * 25 * (primaryPart.AssemblyMass / 20), position)
end

function module.OnUnequip(plr: Player): ()
    local userId = plr.UserId
    local prop = controlledProps[userId]
    if prop then
        stopControllingProp(prop, userId, true)
    end
end

function module.Heartbeat(round: Types.Round): ()
    local props = round:GetMap().Props

    for _, v in props:GetChildren() do
        if v:IsA("BasePart") and v:GetAttribute("Burning") then
            local hitParticipants: {Types.Participant} = {}
            for _, part in v:GetTouchingParts() do
                local char = part:FindFirstAncestorOfClass("Model")
                local plr = Players:GetPlayerFromCharacter(char :: Model)
                if not plr then
                    return
                end

                local participant = round:GetParticipant(plr.Name)
                if not participant or table.find(hitParticipants, participant) then
                    return
                end

                table.insert(hitParticipants, participant)

                local sound = ReplicatedStorage:WaitForChild("WeaponSounds"):WaitForChild("FlareBurn"):Clone()
                sound.PlayOnRemove = true
                sound.Parent = part
                sound:Destroy()

                participant:TryTakeDamage({
                    Amount = 0.25,
                    Source = "Burn",
                })
            end
        end
    end

    for userId, prop in controlledProps do
        local plr = Players:GetPlayerByUserId(userId)
        if not plr then
            stopControllingProp(prop, userId)
            continue
        end
        
        local distance = plr:DistanceFromCharacter(prop.Position)
        if distance == 0 or distance > 30 then -- 30 is quite high but we want to account for network lag and such
            stopControllingProp(prop, userId)
            continue
        end

        local char = plr.Character
        if not char then
            stopControllingProp(prop, userId)
            continue
        end

        local params = OverlapParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Include

        for _, v in workspace:GetPartsInPart(prop) do
            if v.Name:match("Foot") and v.Parent == char and v.Position.Y > prop.Position.Y then
                stopControllingProp(prop, userId)
                continue
            end
        end
    end
end

return module