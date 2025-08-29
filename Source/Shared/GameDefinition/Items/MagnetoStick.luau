local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local GetCentreRay = require(ReplicatedStorage.Shared.Camera.GetCentreRay)
local GetMapThingWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapThingWithTag)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local GetRemote = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.GetRemote)

local module = {}

local INTERACT_DISTANCE = 7.5
local MAX_DISTANCE = 15

local MAX_ROPE_DISTANCE = 6
local ROPE_LENGTH_MULTIPLIER = 1.75

local MAX_SIZE = 6

local PUSH_FORCE_PER_UNIT_MASS = 1000

local ALIGNMENT_RESPONSIVENESS = 80
local ALIGNMENT_DEPTH = 6
local ALIGNMENT_VELOCITY = 100
local ALIGNMENT_FORCE_MULTIPLIER = 1000

local PROP_DAMAGE_TIME = 5

type ClientControl = {
	Prop: Types.MapThing,
	Part: BasePart,
	AlignPosition: AlignPosition,
}

local grabRemote = GetRemote("Grab")
local releaseRemote = GetRemote("Release")

local function serverGetRound(): Types.Round
	local RoundHandler = require(ServerScriptService.RoundHandler)
	local round = RoundHandler.GetRound()
	return round
end

local serverLastHeldBy: {[Types.Prop]: {By: Types.Participant, At: number, Cons: {RBXScriptConnection}}?} = {}
local serverControlledProps: {[Player]: Types.Prop?} = {}

local function getController(prop: Types.MapThing): Player?
	local controllerId = prop:GetAttribute("ControllerId")
	if typeof(controllerId) ~= "number" then
		return nil
	end
	return Players:GetPlayerByUserId(controllerId)
end

local function onPropTouchedServer(prop: Types.Prop, otherPart: BasePart): ()
	if not otherPart:IsDescendantOf(workspace) then
		return -- somehow happened, idk
	end

	if getController(prop.Model) then
		return
	end

	local lastHeld = serverLastHeldBy[prop]
	if not lastHeld then
		return
	end

	if workspace:GetServerTimeNow() - lastHeld.At > PROP_DAMAGE_TIME then
		serverLastHeldBy[prop] = nil
		for _, con in lastHeld.Cons do
			con:Disconnect()
		end
		return
	end

	local part = GetPrimaryPart(prop.Model)
	local energy = 0.5 * part.AssemblyMass * (part.AssemblyLinearVelocity.Magnitude ^ 2)
	if energy < 2000 then
		return
	end

	local damage = (energy - 2000) / 1000
	local params: Types.DamageParams = {
		Amount = damage,
		Source = "Crush",
		Attacker = lastHeld.By,
	}

	prop:TryTakeDamage(params)

	local otherMapThing = GetMapThingWithTag(otherPart, {"Prop", "Character"})
	if not otherMapThing then
		return
	end

	local damageable = prop.Round:GetProp(otherMapThing) or if otherMapThing:IsA("Model") then prop.Round:GetParticipant(otherMapThing) else nil
	if damageable and damageable ~= lastHeld.By then
		(damageable :: Types.Prop):TryTakeDamage(params)
	end
end


function module.SetPropLastHeldBy(prop: Types.Prop, participant: Types.Participant): ()
	if not serverLastHeldBy[prop] then
		prop.Model.Destroying:Connect(function()
			serverLastHeldBy[prop] = nil
		end)
	end
	local cons: {RBXScriptConnection} = {}
	serverLastHeldBy[prop] = {By = participant, At = workspace:GetServerTimeNow(), Cons = cons}
	ForEachPart(prop.Model, function(part)
		local con: RBXScriptConnection
		con = part.Touched:Connect(function(otherPart)
			onPropTouchedServer(prop, otherPart)
		end)
		table.insert(cons, con)
	end)
end

local function isSizeValid(size: Vector3): boolean
	return size.X <= MAX_SIZE and size.Y <= MAX_SIZE and size.Z <= MAX_SIZE
end

local function canGrab(prop: Types.MapThing): boolean
	if prop:HasTag("Interactable") then
		return false
	end
	local part = GetPrimaryPart(prop)
	return (not part:IsGrounded()) and (not prop:GetAttribute("NoGrab")) and isSizeValid(if prop:IsA("Model") then prop:GetExtentsSize() else prop.Size)
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
	local ViewmodelModule = require(ReplicatedStorage.Shared.Combat.ViewmodelModule)

	LocalAnimation.TryPlayAnimation(13269497293, "Magneto")
	ViewmodelModule.PlayAnimation("rbxassetid://13269497293", "Magneto")
end

local function clientMakeAlignPosition(part: BasePart): AlignPosition
	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	alignPosition.ReactionForceEnabled = false
	alignPosition.ApplyAtCenterOfMass = true
	alignPosition.Responsiveness = ALIGNMENT_RESPONSIVENESS
	alignPosition.MaxVelocity = ALIGNMENT_VELOCITY
	alignPosition.MaxForce = ALIGNMENT_FORCE_MULTIPLIER * part.AssemblyMass
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
			module.SetPropLastHeldBy(prop, participant)
		end

		if part then
			releaseRemote:FireClient(player, part)
		end
	end
end

local function clientGetProp(part: BasePart): Types.MapThing?
	return GetMapThingWithTag(part, "Prop")
end

local function clientRelease(part: BasePart, doNotFireServer: boolean?): ()
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
end

if RunService:IsClient() then
	releaseRemote.OnClientEvent:Connect(function(part: BasePart): ()
		if clientControl and clientControl.Part == part then
			clientRelease(part, true)
		end
	end)
end

local function clientGrab(part: BasePart): ()
	local prop = clientGetProp(part)
	if not prop or not canGrab(prop) then
		return
	end

	grabRemote:FireServer(part)

	clientAnimate()

	clientControl = {
		Prop = prop,
		Part = part,
		AlignPosition = clientMakeAlignPosition(part),
	}
end

local clientRaycastParams = RaycastParams.new()
clientRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
clientRaycastParams.CollisionGroup = "WeaponHitTargets"
clientRaycastParams.IgnoreWater = true

local function clientRaycast(): BasePart?
	local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
	local char = LocalCharacter.Character()
	local head = LocalCharacter.Head()
	if not char or not head then
		return nil
	end

	clientRaycastParams.FilterDescendantsInstances = {char}

	local result = workspace:Raycast(head.Position, GetCentreRay().Direction * MAX_DISTANCE, clientRaycastParams)
	if not result then
		return nil
	end

	return result.Instance
end

local function onUnequipClient(): ()
	if clientControl then
		clientRelease(clientControl.Part)
	end
end

local function onUnequipServer(_, participant: Types.Participant): ()
	module.ServerStopControllingProp(participant.Player)
end

local function alternateFireClient(_, _, origin: Vector3, direction: Vector3): ()
	local part = clientRaycast()

	if part and clientControl and part == clientControl.Part and clientGetProp(part) == clientControl.Prop then
		return clientRelease(clientControl.Part)
	end

	if clientControl then
		clientRelease(clientControl.Part)
	end

	if part then
		return clientGrab(part)
	end
end

local function serverGetPropFromPart(part: unknown): Types.Prop?
	if typeof(part) ~= "Instance" then
		return nil
	end

	if not part:IsA("BasePart") then
		return nil
	end

	local mapThing = GetMapThingWithTag(part, "Prop")
	if not mapThing then
		return nil
	end

	return serverGetRound():GetProp(mapThing)
end

if RunService:IsServer() then
	releaseRemote.OnServerEvent:Connect(function(player: Player, part: unknown)
		local prop = serverGetPropFromPart(part)
		if prop == serverControlledProps[player] then
			module.ServerStopControllingProp(player)
		end
	end)

	grabRemote.OnServerEvent:Connect(function(player: Player, part: unknown): ()
		local prop = serverGetPropFromPart(part)
		if not prop then
			releaseRemote:FireClient(player, part)
			return
		end

		if not canGrab(prop.Model) then
			releaseRemote:FireClient(player, part)
			return
		end

		module.ServerStopControllingProp(player)
		serverBeginControllingProp(prop, player)

		return true
	end)
end

local function clientIsAbovePart(root: BasePart, part: BasePart): boolean
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {part}
	params.FilterType = Enum.RaycastFilterType.Include

	local result = workspace:Blockcast(root.CFrame, root.Size, -root.CFrame.UpVector * 3, params)
	return result ~= nil
end

Players.PlayerRemoving:Connect(function(player)
	module.ServerStopControllingProp(player)
end)

local postSimulationClient: (item: Types.AnyItem, dt: number) -> () = function(): ()
	if not clientControl then
		return
	end

	local part = clientControl.Part

	local distance = Players.LocalPlayer:DistanceFromCharacter(part.Position)
	if distance == 0 or distance > MAX_DISTANCE then
		return clientRelease(part)
	end

	if not part:IsDescendantOf(workspace) then
		return clientRelease(part)
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
		return clientRelease(part)
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char, part}
	if part:IsDescendantOf(workspace.Characters) then
		local model = part:FindFirstAncestorOfClass("Model")
		if model then
			params:AddToFilter(model)
		end
	end
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.RespectCanCollide = true

	local centreRay = GetCentreRay(ALIGNMENT_DEPTH)
	local result = workspace:Raycast(GetCentreRay(0).Origin, centreRay.Direction * ALIGNMENT_DEPTH, params)

	local targetPosition = if result then result.Position else centreRay.Origin
	clientControl.AlignPosition.Position = targetPosition
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",
	Name = "Magneto Stick",
    Slot = 5,
    CanDrop = false,

    Model = ReplicatedStorage.Assets.WeaponModels["Magneto Stick"],
    HoldAnimation = "rbxassetid://10247423634",

	AlternateToggled = true,

    -- PrimaryFireClient = primaryFireClient,
    AlternateFireClient = alternateFireClient,

	OnUnequipClient = onUnequipClient,
	OnUnequipServer = onUnequipServer,

	PostSimulationClient = postSimulationClient,

    PrimaryHint = "Push Prop",
    AlternateHint = "Grab Prop",
}

module.Item = item

return module