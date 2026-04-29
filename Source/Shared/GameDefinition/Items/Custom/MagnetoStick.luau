local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local GetAssemblyMass = require(ReplicatedStorage.API.GetAssemblyMass)
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local GetCentreRay = require(ReplicatedStorage.Shared.Camera.GetCentreRay)
local GetMapObjectWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapObjectWithTag)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local Types = require(ReplicatedStorage.API.Types)

local module = {}

module.Item = (nil :: any) :: Types.ItemComponents

local INTERACT_DISTANCE = 7.5
local MAX_DISTANCE = 15

local MAX_ROPE_DISTANCE = 6
local ROPE_LENGTH_MULTIPLIER = 1.75

local MAX_SIZE = 6

local PUSH_FORCE_PER_UNIT_MASS = 1

local ALIGNMENT_RESPONSIVENESS = 40
local ALIGNMENT_DEPTH = 6
local ALIGNMENT_VELOCITY = 100
local ALIGNMENT_FORCE_MULTIPLIER = 1000

type ClientControl = {
	Prop: Types.MapObject,
	Part: BasePart,
	AlignPosition: AlignPosition,
}

local grabRemote = GetRemote("Grab", script)
local releaseRemote = GetRemote("Release", script)
local hangRemote = GetRemote("Hang", script)

local function serverGetRound(): Types.Round
	local RoundHandler = require(ServerScriptService.RoundHandler)
	local round = RoundHandler.GetRound()
	return round
end

local serverControlledProps: {[Player]: Types.Prop?} = {}

local clientRaycastParams = RaycastParams.new()
clientRaycastParams.CollisionGroup = "WeaponHitTargets"
clientRaycastParams.IgnoreWater = true

local function clientRaycast(filter: {Instance} | Instance?): (BasePart?, Vector3?)
	local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
	local char = LocalCharacter.Character()
	local head = LocalCharacter.Head()
	if not char or not head then
		return nil, nil
	end

	local newFilter = if typeof(filter) == "table" then table.clone(filter) else {filter :: Instance}
	table.insert(newFilter, char)

	clientRaycastParams.ExcludeInstances = newFilter

	local result = workspace:Raycast(head.Position, GetCentreRay().Direction * INTERACT_DISTANCE, clientRaycastParams)
	if not result then
		return nil, nil
	end

	return result.Instance, result.Position
end

local function isSizeValid(size: Vector3): boolean
	return size.X <= MAX_SIZE and size.Y <= MAX_SIZE and size.Z <= MAX_SIZE
end

local function canGrab(prop: Types.MapObject): boolean
	if prop:HasTag("Interactable") and not prop:HasTag("Item") then
		return false
	end
	local part = GetPrimaryPart(prop)
	return (not part:IsGrounded()) and (not prop:GetAttribute("NoGrab")) and isSizeValid(if prop:IsA("Model") then (prop:GetExtentsSize() * if prop:HasTag("Corpse") then 0 else 1) else prop.Size)
end

local function canPush(prop: Types.MapObject): boolean
	if prop:HasTag("Interactable") and not prop:HasTag("Item") then
		return false
	end
	local part = GetPrimaryPart(prop)
	return (not part:IsGrounded()) and (not prop:GetAttribute("NoPush"))
end

local function createOrFindAttachment(part: BasePart): Attachment
	local attachment = part:FindFirstChild("MagnetoAttachment")
	if not attachment then
		local newAttachment = Instance.new("Attachment")
		newAttachment.Name = "MagnetoAttachment"
		newAttachment.Parent = part
		attachment = newAttachment
	end

	assert(attachment and attachment:IsA("Attachment"), "Attachment is not an Attachment")
	return attachment
end

local function clientAnimate(): ()
	local LocalAnimation = require(ReplicatedStorage.Shared.Character.LocalAnimation)
	local Viewmodel = require(ReplicatedStorage.Shared.Combat.Viewmodel)

	LocalAnimation.TryPlayAnimation(Content.fromAssetId(13269497293), "Magneto")
	Viewmodel.PlayAnimation(Content.fromAssetId(13269497293), "Magneto")
end

local function clientMakeAlignPosition(part: BasePart): AlignPosition
	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	alignPosition.ReactionForceEnabled = false
	alignPosition.ApplyAtCenterOfMass = true
	alignPosition.Responsiveness = ALIGNMENT_RESPONSIVENESS
	alignPosition.MaxVelocity = ALIGNMENT_VELOCITY
	alignPosition.MaxForce = ALIGNMENT_FORCE_MULTIPLIER * GetAssemblyMass(part)
	alignPosition.Attachment0 = createOrFindAttachment(part)
	alignPosition.Parent = part
	return alignPosition
end

local clientControl: ClientControl?

local function setNetworkOwner(prop: Types.Prop, owner: Player | "Auto"): ()
	if not prop.Model:IsDescendantOf(workspace) then
		return
	end

	local part = GetPrimaryPart(prop.Model)

	if not part:CanSetNetworkOwnership() then
		return
	end

	if owner == "Auto" then
		return part:SetNetworkOwnershipAuto()
	end
	part:SetNetworkOwner(owner)
end

local function serverBeginControllingProp(prop: Types.Prop, player: Player): ()
	setNetworkOwner(prop, player)
	prop.Model:SetAttribute("ControllerId", player.UserId)
	serverControlledProps[player] = prop
end

function module.ServerStopControllingProp(player: Player, part: BasePart?): ()
	local prop = serverControlledProps[player]
	if prop then
		setNetworkOwner(prop, "Auto")
		prop.Model:SetAttribute("ControllerId", nil)
		serverControlledProps[player] = nil

		local participant = serverGetRound():GetParticipant(player)
		if participant then
			local PropDamage = require(ServerScriptService.Combat.PropDamage)
			PropDamage.SetLastHolder(prop, participant)
		end

		if part then
			releaseRemote:FireClient(player, part)
		end
	end
end

local function clientGetProp(part: BasePart): Types.MapObject?
	return GetMapObjectWithTag(part, "Prop")
end

local function clientRelease(item: Types.Item?, part: BasePart, doNotFireServer: boolean?): ()
	local UpdateItemHint = require(ReplicatedStorage.API.UpdateItemHint)
	if not clientControl then
		return
	end

	if clientControl.Part ~= part then
		return
	end

	if not doNotFireServer then
		releaseRemote:FireServer(part)
	end

	clientAnimate()

	clientControl.AlignPosition:Destroy()
	clientControl = nil

	if item then
		UpdateItemHint(item, "primary", "Push Prop")
	end
end

if RunService:IsClient() then
	releaseRemote.OnClientEvent:Connect(function(part: BasePart): ()
		local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)
		local item = ClientInventory.GetItem("Magneto Stick")
		if clientControl and clientControl.Part == part then
			clientRelease(item, part, true)
		end
	end)
end

local function destroyRope(part: BasePart): ()
	local rope = part:FindFirstChild("MagnetoRope")
	if rope and rope:IsA("RopeConstraint") then
		if rope.Attachment1 then
			rope.Attachment1:Destroy()
		end
		if rope.Attachment0 then
			rope.Attachment0:Destroy()
		end
		rope:Destroy()
	end
end

local function clientGrab(item: Types.Item, part: BasePart): ()
	local UpdateItemHint = require(ReplicatedStorage.API.UpdateItemHint)
	local prop = clientGetProp(part)
	if not prop or not canGrab(prop) then
		return
	end

	if prop:HasTag("Corpse") then
		UpdateItemHint(item, "primary", "Pin Limb")
	end

	grabRemote:FireServer(part)

	clientAnimate()

	clientControl = {
		Prop = prop,
		Part = part,
		AlignPosition = clientMakeAlignPosition(part),
	}
end

local function clientPush(part: BasePart, position: Vector3, origin: Vector3): ()
	local prop = clientGetProp(part)
	if not prop or not canPush(prop) then
		return
	end

	part:ApplyImpulseAtPosition((position - origin).Unit * PUSH_FORCE_PER_UNIT_MASS * GetAssemblyMass(part), position)
end

local function clientHang(item: Types.Item): ()
	assert(clientControl, "clientControl is nil")

	local to, at = clientRaycast(clientControl.Prop)
	if not to or not at then
		return
	end

	local part = clientControl.Part
	if (part.Position - at).Magnitude > MAX_ROPE_DISTANCE then
		return
	end

	hangRemote:FireServer(part, to, at)
	clientRelease(item, part, true)
end

local function onUnequipClient(item: Types.Item): ()
	if clientControl then
		clientRelease(item, clientControl.Part)
	end
end

local function onUnequipServer(_, participant: Types.Participant): ()
	module.ServerStopControllingProp(participant.Player)
end

local function alternateFireClient(item: Types.Item, origin: Vector3, direction: Vector3): true
	local part = clientRaycast()

	if part and clientControl and part == clientControl.Part and clientGetProp(part) == clientControl.Prop then
		clientRelease(item, clientControl.Part)
		return true
	end

	if clientControl then
		clientRelease(item, clientControl.Part)
	end

	if part then
		clientGrab(item, part)
		return true
	end

	return true
end

local function primaryFireClient(item: Types.Item, origin: Vector3, direction: Vector3): true
	local part, position = clientRaycast()
	if not part or not position then
		return true
	end

	if clientControl then
		if clientControl.Prop:HasTag("Corpse") then
			clientHang(item)
		end
		return true
	end

	clientPush(part, position, origin)
	return true
end

local function serverGetPropFromPart(part: unknown): Types.Prop?
	if typeof(part) ~= "Instance" then
		return nil
	end

	if not part.Parent then
		return nil
	end

	if not part:IsA("BasePart") then
		return nil
	end

	local MapObject = GetMapObjectWithTag(part, "Prop")
	if not MapObject then
		return nil
	end

	return serverGetRound():GetProp(MapObject)
end

if RunService:IsServer() then
	releaseRemote.OnServerEvent:Connect(function(player: Player, part: unknown)
		local prop = serverGetPropFromPart(part)
		if prop == serverControlledProps[player] then
			module.ServerStopControllingProp(player)
		end
	end)

	hangRemote.OnServerEvent:Connect(function(player: Player, part: unknown, to: unknown, at: unknown): ()
		if typeof(part) ~= "Instance" or typeof(to) ~= "Instance" or typeof(at) ~= "Vector3" then
			return
		end

		if not part:IsA("BasePart") or not to:IsA("BasePart") then
			return
		end

		if (part.Position - at).Magnitude > MAX_ROPE_DISTANCE * 1.1 then
			return
		end

		local localPosition = to.CFrame:ToObjectSpace(CFrame.new(at))
		if localPosition.Position.Magnitude > to.ExtentsSize.Magnitude * 1.1 then
			return
		end

		local prop = serverControlledProps[player]
		if not prop or (part ~= prop.Model :: Instance and not part:IsDescendantOf(prop.Model)) or not prop.Model:HasTag("Corpse") then
			return
		end

		-- Here we can also check for whether the attaching to part is not a prop.
		-- But actually it's funnier if you can hang corpses to props.

		local rope = Instance.new("RopeConstraint")
		rope.Name = "MagnetoRope"
		rope.Attachment0 = Instance.new("Attachment", part)

		local attachment = Instance.new("Attachment")
		attachment.Name = "MagnetoRopeAttachment"
		attachment.Position = localPosition.Position
		attachment.Parent = to

		rope.Attachment1 = attachment
		rope.Visible = true
		rope.Thickness = 0.25
		rope.Length = (part.Position - at).Magnitude * ROPE_LENGTH_MULTIPLIER

		rope.Parent = part
	end)

	grabRemote.OnServerEvent:Connect(function(player: Player, part: unknown): ()
		local prop = serverGetPropFromPart(part)
		if not prop then
			releaseRemote:FireClient(player, part)
			return
		end

		assert(typeof(part) == "Instance" and part:IsA("BasePart"))

		if not canGrab(prop.Model) then
			releaseRemote:FireClient(player, part)
			return
		end

		destroyRope(part)
		module.ServerStopControllingProp(player)
		serverBeginControllingProp(prop, player)

		return true
	end)
end

local function clientIsAbovePart(root: BasePart, part: BasePart): boolean
	local params = RaycastParams.new()
	params.IncludeInstances = {part}

	local result = workspace:Raycast(root.Position, -root.CFrame.UpVector * 8, params)
	return result ~= nil
end

Players.PlayerRemoving:Connect(function(player)
	module.ServerStopControllingProp(player)
end)

local function postSimulationClient(item: Types.Item): ()
	if not clientControl then
		return
	end

	local part = clientControl.Part

	local distance = Players.LocalPlayer:DistanceFromCharacter(part.Position)
	if distance == 0 or distance > MAX_DISTANCE then
		return clientRelease(item, part)
	end

	if not part:IsDescendantOf(workspace) then
		return clientRelease(item, part, true)
	end

	local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)

	local char = LocalCharacter.Character()
	if not char then
		return
	end

	local root = char.PrimaryPart
	if not root then
		return
	end

	if PhysicsService:CollisionGroupsAreCollidable(root.CollisionGroup, part.CollisionGroup) and clientIsAbovePart(root, part) then
		return clientRelease(item, part)
	end

	local prop = GetMapObjectWithTag(part, "Prop")

	local params = RaycastParams.new()
	params.ExcludeInstances = {char, prop or part}
	params.IgnoreWater = true
	params.RespectCanCollide = true

	local centreRay = GetCentreRay(ALIGNMENT_DEPTH, true)
	local result = workspace:Raycast(GetCentreRay(0, true).Origin, centreRay.Direction * ALIGNMENT_DEPTH, params)

	local targetPosition = if result then result.Position else centreRay.Origin
	clientControl.AlignPosition.Position = targetPosition
end

local item = Custom({
	Name = "Magneto Stick",
	Description = "Grab stuff and push stuff",
	IconContent = Content.none,

    ItemGroup = {
		PreferredSlot = 5,
	},
    DropDisabled = true,

    Model = ReplicatedStorage.Assets.ItemModels["Magneto Stick"],
    HoldAnimation = Content.fromAssetId(10247423634),

	AlternateToggled = true,

    PrimaryFireClient = primaryFireClient,
    AlternateFireClient = alternateFireClient,

	OnUnequipClient = onUnequipClient,
	OnUnequipServer = onUnequipServer,

	PostSimulationClient = postSimulationClient,

    PrimaryHint = "Push Prop",
    AlternateHint = "Grab Prop",
})

module.Item = item

return table.freeze(module)