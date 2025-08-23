local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetCentreRay = require(ReplicatedStorage.Shared.Camera.GetCentreRay)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)

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

local module = {}

local serverLastHeldBy: {[Types.Prop]: {By: Player, At: number}?} = {}
local serverTouchedConnections: {[Types.Prop]: {RBXScriptConnection}?} = {}

local stopControllingPropRemote: RemoteEvent
if RunService:IsServer() then
	stopControllingPropRemote = Instance.new("RemoteEvent")
	stopControllingPropRemote.Name = "StopControllingProp"
	stopControllingPropRemote.Parent = script
else
	local found = script:WaitForChild("StopControllingProp")
	assert(found:IsA("RemoteEvent"), "StopControllingProp must be a RemoteEvent")
	stopControllingPropRemote = found
end

local makeRopeRemote: RemoteEvent
if RunService:IsServer() then
	makeRopeRemote = Instance.new("RemoteEvent")
	makeRopeRemote.Name = "MakeRope"
	makeRopeRemote.Parent = script
else
	local found = script:WaitForChild("MakeRope")
	assert(found:IsA("RemoteEvent"), "MakeRope must be a RemoteEvent")
	makeRopeRemote = found
end

local removeRopesRemote: RemoteEvent
if RunService:IsServer() then
	removeRopesRemote = Instance.new("RemoteEvent")
	removeRopesRemote.Name = "RemoveRopes"
	removeRopesRemote.Parent = script
else
	local found = script:WaitForChild("RemoveRopes")
	assert(found:IsA("RemoteEvent"), "RemoveRopes must be a RemoteEvent")
	removeRopesRemote = found
end

local function models(name: string): BasePart
    return ReplicatedStorage.Assets:WaitForChild("WeaponModels"):WaitForChild(name) :: BasePart
end

local serverGrabbedProps: {[Player]: Types.Prop?} = {}

local currentGrabClient: AlignPosition?

local function animate(): ()
	local LocalAnimation = require(ReplicatedStorage.Shared.Character.LocalAnimation)
	local ViewmodelModule = require(ReplicatedStorage.Shared.Combat.ViewmodelModule)

	LocalAnimation.TryPlayAnimation(13269497293, "Magneto")
	ViewmodelModule.PlayAnimation("rbxassetid://13269497293", "Magneto")
end

local function getPrimaryInstance(prop: Types.Prop | Types.MapThing): Types.MapThing
	local model: Types.MapThing
	if typeof(prop) == "table" then
		model = prop.Model
	else
		model = prop
	end

	local instance: Types.MapThing = model
	if model:IsDescendantOf(workspace.Characters) then
		local foundModel = model:FindFirstAncestorOfClass("Model")
		if foundModel and foundModel:HasTag("Corpse") then
			instance = foundModel
		end
	end

	return instance
end

local function getPrimaryPart(prop: Types.Prop | Types.MapThing): BasePart?
	local model = getPrimaryInstance(prop)

	if model:IsA("Model") then
		return model.PrimaryPart
	end

	return model
end

local function isPropSmallEnough(part: BasePart): boolean
	local size = part.Size
	if part.AssemblyMass > 160 or (size.X * size.Y * size.Z) > 50 or size.X > MAX_SIZE or size.Y > MAX_SIZE or size.Z > MAX_SIZE then
		return false
	end

	return true
end

local function canGrab(part: BasePart): boolean
	if part:IsGrounded() then
		return false
	end
	
	if not isPropSmallEnough(part) then
		return false
	end

	if part:GetAttribute("NoGrab") then
		return false
	end

	return true
end

type NetworkOwnerParameter = Player | "Auto"
local function setNetworkOwnerOfPart(part: BasePart, owner: NetworkOwnerParameter): ()
	if not part:IsDescendantOf(workspace) then
		return
	end

	if owner == "Auto" then
		return part:SetNetworkOwnershipAuto()
	end

	part:SetNetworkOwner(owner)
end

local function setNetworkOwnerOfProp(prop: Types.Prop, owner: NetworkOwnerParameter): ()
	local part = getPrimaryPart(prop)
	if not part then
		return
	end
	setNetworkOwnerOfPart(part, owner)
end

local function getControllerObject(prop: Types.MapThing): IntValue?
	local controllerObject = prop:FindFirstChild("MagnetoController")
	if not controllerObject or not controllerObject:IsA("IntValue") then
		return nil
	end
	
	return controllerObject
end

local function getController(prop: Types.MapThing): Player?
	local controllerObject = getControllerObject(prop)
	if not controllerObject then
		return nil
	end

	local player = Players:GetPlayerByUserId(controllerObject.Value)
	return player
end

local function onPropTouchedServer(prop: Types.Prop, otherPart: BasePart, cons: {RBXScriptConnection}): ()
	local part = getPrimaryPart(prop)
	if not part then
		return
	end

	local instance = getPrimaryInstance(prop)
	if not instance then
		return
	end

	local currentHolder = getController(instance)
	if currentHolder then
		return
	end

	local lastHolder = serverLastHeldBy[prop]
	if not lastHolder or lastHolder.At + PROP_DAMAGE_TIME < workspace:GetServerTimeNow() then
		serverTouchedConnections[prop] = nil
		for _, con in cons do
			con:Disconnect()
		end
		return
	end

	local lastHolderParticipant = prop.Round:GetParticipant(lastHolder.By.Name)
	if not lastHolderParticipant then
		return
	end

	local energy = 0.5 * part.AssemblyMass * (part.AssemblyLinearVelocity.Magnitude ^ 2)
	if energy < 2000 then
		return
	end

	local damage = (energy - 2000) / 1000
	local params: Types.DamageParams = {
		Amount = damage,
		Source = "Crush",
		Attacker = lastHolderParticipant,
	}

	prop:TryTakeDamage(params)

	local char = otherPart:FindFirstAncestorOfClass("Model")
	if not char then
		return
	end

	local participant = prop.Round:GetParticipant(char.Name)
	if not participant or participant == lastHolderParticipant then
		return
	end

	participant:TryTakeDamage(params)
end

local function stopControllingPropClient(doNotFireServer: boolean?): ()
	if not currentGrabClient then
		return
	end

	if not doNotFireServer then
		stopControllingPropRemote:FireServer()
	end

	currentGrabClient:Destroy()
	currentGrabClient = nil

	animate()
end

function module.SetLastHeldBy(prop: Types.Prop, by: Player?): ()
	if not by then
		serverLastHeldBy[prop] = nil
	else
		serverLastHeldBy[prop] = {By = by, At = workspace:GetServerTimeNow()}
		if not serverTouchedConnections[prop] then
			local cons: {RBXScriptConnection} = {}

			ForEachPart(prop.Model, function(part)
				local con: RBXScriptConnection
				con = part.Touched:Connect(function(otherPart)
					onPropTouchedServer(prop, otherPart, cons)
				end)
				table.insert(cons, con)
			end)

			serverTouchedConnections[prop] = cons

			prop.Model.Destroying:Once(function()
				serverTouchedConnections[prop] = nil
				module.SetLastHeldBy(prop)
			end)
		end
	end
end

local function stopControllingPropServer(player: Player): ()
	local prop = serverGrabbedProps[player]
	if not prop then
		return
	end

	local part = getPrimaryPart(prop)
	if not part then
		return
	end

	local controllerObject = getControllerObject(getPrimaryInstance(prop))
	if controllerObject then
		controllerObject.Value = 0
	end

	setNetworkOwnerOfPart(part, "Auto")

	serverGrabbedProps[player] = nil

	if prop.Kind == "Prop" and not serverTouchedConnections[prop] then
		module.SetLastHeldBy(prop, player)
	end
end

local function canControl(prop: Types.Prop | Types.MapThing): boolean
	local controller = getController(getPrimaryInstance(prop))
	return not controller
end

local function isControlledBy(prop: Types.MapThing, player: Player): boolean
	local controller = getController(getPrimaryInstance(prop))
	return controller == player
end

local function createOrFindAttachment(prop: BasePart): Attachment
	local attachment = prop:FindFirstChild("MagnetoAttachment")
	if not attachment then
		local newAttachment = Instance.new("Attachment")
		newAttachment.Name = "MagnetoAttachment"
		newAttachment.Parent = prop
		attachment = newAttachment
	end

	assert(attachment and attachment:IsA("Attachment"), "Attachment is not an Attachment")
	return attachment
end

local function removeRopes(part: BasePart): ()
	local folder = part:FindFirstChild("MagnetoRopes")
	if folder then
		assert(folder:IsA("Folder"), "MagnetoRopes is not a folder")
		for _, v in folder:GetChildren() do
			if not v:IsA("RopeConstraint") then
				continue
			end

			local attachment0 = v.Attachment0
			if attachment0 then
				attachment0:Destroy()
			end

			local attachment1 = v.Attachment1
			if attachment1 then
				attachment1:Destroy()
			end

			v:Destroy()
		end
	end
end

if RunService:IsServer() then
	stopControllingPropRemote.OnServerEvent:Connect(function(player)
		stopControllingPropServer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		stopControllingPropServer(player)
		if serverGrabbedProps[player] then
			serverGrabbedProps[player] = nil
		end 
	end)

	removeRopesRemote.OnServerEvent:Connect(function(player, part: unknown): ()
		if typeof(part) ~= "Instance" then
			return
		end

		if not part:IsA("BasePart") then
			return
		end

		local model = part:FindFirstAncestorOfClass("Model")
		if not model or not model:HasTag("Corpse") then
			return
		end

		local prop = serverGrabbedProps[player]
		if not prop or prop.Model ~= model then
			return
		end

		removeRopes(part)
	end)

	makeRopeRemote.OnServerEvent:Connect(function(player, part: unknown, attachTo: unknown, position: unknown)
		if typeof(part) ~= "Instance" or typeof(attachTo) ~= "Instance" or typeof(position) ~= "Vector3" then
			return
		end

		if not part:IsA("BasePart") or not attachTo:IsA("BasePart") then
			return
		end

		if (part.Position - position).Magnitude > MAX_ROPE_DISTANCE then
			return
		end

		local model = part:FindFirstAncestorOfClass("Model")
		if not model or not model:HasTag("Corpse") then
			return
		end

		local prop = serverGrabbedProps[player]
		if not prop or prop.Model ~= model then
			return
		end

		local folder: Folder
		local temp = part:FindFirstChild("MagnetoRopes")
		if not temp then
			folder = Instance.new("Folder")
			folder.Name = "MagnetoRopes"
			folder.Parent = part
		else
			assert(temp:IsA("Folder"), "MagnetoRopes is not a folder")
			folder = temp
			removeRopes(part)
		end

		local asLocal = attachTo.CFrame:ToObjectSpace(CFrame.new(position))
		if asLocal.Position.Magnitude > attachTo.ExtentsSize.Magnitude * 1.1 then
			return
		end

		local rope = Instance.new("RopeConstraint")
		rope.Attachment0 = Instance.new("Attachment", part)

		local attachment = Instance.new("Attachment")
		attachment.Position = asLocal.Position
		attachment.Parent = attachTo

		rope.Attachment1 = attachment
		rope.Visible = true
		rope.Thickness = 0.25
		rope.Length = (part.Position - position).Magnitude * ROPE_LENGTH_MULTIPLIER

		rope.Name = "MagnetoRope"

		rope.Parent = folder
	end)
end

local function startControllingPropClient(prop: BasePart): ()
	if not canControl(getPrimaryInstance(prop)) then
		return
	end

	local part = getPrimaryPart(prop)
	if not part then
		return
	end

	if not canGrab(part) then
		return
	end

	task.defer(removeRopesRemote.FireServer, removeRopesRemote, prop)

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	alignPosition.ReactionForceEnabled = false
	alignPosition.ApplyAtCenterOfMass = true
	alignPosition.Responsiveness = ALIGNMENT_RESPONSIVENESS
	alignPosition.MaxVelocity = ALIGNMENT_VELOCITY
	alignPosition.MaxForce = ALIGNMENT_FORCE_MULTIPLIER * part.AssemblyMass

	alignPosition.Attachment0 = createOrFindAttachment(prop)
	alignPosition.Parent = prop

	currentGrabClient = alignPosition

	animate()
end

local function pushPropClient(prop: Types.MapThing): ()
	if not canControl(getPrimaryInstance(prop)) then
		return
	end
	
	local part = getPrimaryPart(prop)
	if not part then
		return
	end

	local centreRay = GetCentreRay()
	part:ApplyImpulseAtPosition(centreRay.Direction * ((PUSH_FORCE_PER_UNIT_MASS * part.AssemblyMass) / 500), part:GetClosestPointOnSurface(centreRay.Origin))
end

local function getPropClient(origin: Vector3, direction: Vector3): BasePart?
	local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
	local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local GetMapThingWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapThingWithTag)

	local char = LocalCharacter.Character()
	if not char then
		return nil
	end

	local map = LocalRoundInfo.Map()
	if not map then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	local result = workspace:Raycast(origin, direction * INTERACT_DISTANCE, params)
	if not result then
		return nil
	end

	local part = result.Instance :: BasePart

	if not part:IsDescendantOf(map.Dynamic) and not GetMapThingWithTag(part, "Corpse") then
		return nil
	end

	return part
end

local lastHang = 0 -- magneto stick primary fire is not toggled, so it will run twice per click. this aims to mitigate that.
local function tryHang(origin: Vector3, direction: Vector3): boolean
	if tick() - lastHang < 0.1 then
		return false
	end
	lastHang = tick()

	if not currentGrabClient or not currentGrabClient:IsDescendantOf(workspace.Characters) then
		return false
	end

	local part = currentGrabClient.Parent
	if not part or not part:IsA("BasePart") then
		return false
	end

	local model = currentGrabClient:FindFirstAncestorOfClass("Model")
	if not model then
		return false
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {workspace.Characters}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	local result = workspace:Raycast(origin, direction * INTERACT_DISTANCE, params)
	if not result then
		return false
	end

	if (part.Position - result.Position).Magnitude > MAX_ROPE_DISTANCE then
		return false
	end

	makeRopeRemote:FireServer(part, result.Instance, result.Position)

	return true
end

local function primaryFireClient(_, _, origin: Vector3, direction: Vector3): ()
	if tryHang(origin, direction) then
		return stopControllingPropClient()
	end

	local prop = getPropClient(origin, direction)
	if not prop then
		return
	end
	pushPropClient(prop)
end

local function alternateFireClient(_, _, origin: Vector3, direction: Vector3): ()
	stopControllingPropClient(true)

	local prop = getPropClient(origin, direction)
	if not prop then
		return
	end

	if not isControlledBy(getPrimaryInstance(prop), Players.LocalPlayer) then
		startControllingPropClient(prop)
	end
end

local function onUnequipClient(): ()
	stopControllingPropClient(true)
end

local function onUnequipServer(_, participant: Types.Participant): ()
	stopControllingPropServer(participant.Player)
end

local function isAbovePart(root: BasePart, part: BasePart): boolean
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {part}
	params.FilterType = Enum.RaycastFilterType.Include

	local result = workspace:Blockcast(root.CFrame, root.Size, -root.CFrame.UpVector * 3, params)
	return result ~= nil
end

local postSimulationClient: (item: Types.AnyItem, dt: number) -> () = function(): ()
	if not currentGrabClient then
		return
	end

	local part = currentGrabClient.Parent
	assert(part and part:IsA("BasePart"), "Part must be a BasePart")

	local distance = Players.LocalPlayer:DistanceFromCharacter(part.Position)
	if distance == 0 or distance > MAX_DISTANCE then
		return stopControllingPropClient()
	end

	if not part:IsDescendantOf(workspace) then
		return stopControllingPropClient()
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

	if PhysicsService:CollisionGroupsAreCollidable(root.CollisionGroup, part.CollisionGroup) and isAbovePart(root, part) then
		return stopControllingPropClient()
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char, part}
	if part:IsDescendantOf(workspace.Corpses) then
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
	currentGrabClient.Position = targetPosition
end

local function getPropServer(participant: Types.Participant, origin: Vector3, direction: Vector3): Types.Prop?
	local char = participant:GetCharacter()
	if not char then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	local result = workspace:Raycast(origin, direction * INTERACT_DISTANCE, params)
	if not result then
		return nil
	end

	local part = result.Instance :: BasePart

	local model: Types.MapThing? = part
	if part:IsDescendantOf(workspace.Characters) then
		model = part:FindFirstAncestorOfClass("Model")
	end

	if not model or not model:HasTag("Corpse") then
		return nil
	end

	local prop = participant.Round:GetProp(model)
	return prop
end

local function fireServer(_, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): ()
	local prop = getPropServer(participant, origin, direction)
	if not prop then
		if mode == "Alternate" then
			stopControllingPropServer(participant.Player)
		end
		return
	end

	local part = getPrimaryPart(prop)
	if not part then
		return
	end

	if isControlledBy(getPrimaryInstance(prop), participant.Player) then
		if mode == "Alternate" then
			stopControllingPropServer(participant.Player)
		end
		return
	end

	if not canControl(getPrimaryInstance(prop)) then
		return stopControllingPropServer(participant.Player)
	end

	stopControllingPropServer(participant.Player)

	if mode == "Alternate" then
		if not canGrab(part) then
			return
		end

		local controllerObject = getControllerObject(getPrimaryInstance(prop))
		if not controllerObject then
			local newObject = Instance.new("IntValue")
			newObject.Name = "MagnetoController"
			newObject.Parent = getPrimaryInstance(prop)

			controllerObject = newObject
		end

		assert(controllerObject)
		controllerObject.Value = participant.Player.UserId

		serverGrabbedProps[participant.Player] = prop
	end

	setNetworkOwnerOfProp(prop, participant.Player)
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",
	Name = "Magneto Stick",
    Slot = 5,
    CanDrop = false,

    Model = models("Magneto Stick"),
    HoldAnimation = "rbxassetid://10247423634",

	AlternateToggled = true,

    PrimaryFireClient = primaryFireClient,
    AlternateFireClient = alternateFireClient,

    PrimaryFireServer = fireServer,
    AlternateFireServer = fireServer,

	OnUnequipClient = onUnequipClient,
	OnUnequipServer = onUnequipServer,

	PostSimulationClient = postSimulationClient,

    PrimaryHint = "Push Prop",
    AlternateHint = "Grab Prop",
}

module.Item = item

return module