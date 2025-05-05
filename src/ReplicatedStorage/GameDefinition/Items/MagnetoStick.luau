local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetCentreRay = require(ReplicatedStorage.GetCentreRay)
local Types = require(ReplicatedStorage.RoundRule.Types)

local INTERACT_DISTANCE = 7.5
local MAX_DISTANCE = 15

local PUSH_FORCE_PER_UNIT_MASS = 1000

local ALIGNMENT_RESPONSIVENESS = 200
local ALIGNMENT_DEPTH = 6

local PROP_DAMAGE_TIME = 5

local module = {}

local serverLastHeldBy: {[Types.MapProp]: {By: Player, At: number}?} = {}
local serverTouchedConnections: {[Types.MapProp]: RBXScriptConnection?} = {}

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

local function models(name: string): BasePart
    return ReplicatedStorage:WaitForChild("WeaponModels"):WaitForChild(name) :: BasePart
end

local serverGrabbedProps: {[Player]: Types.Prop?} = {}

local currentGrabClient: AlignPosition?

local function animate(): ()
	local LocalAnimation = require(ReplicatedStorage.LocalAnimation)
	local ViewmodelModule = require(ReplicatedStorage.ViewmodelModule)

	LocalAnimation.TryPlayAnimation(13269497293, "Magneto")
	ViewmodelModule.PlayAnimation("rbxassetid://13269497293", "Magneto")
end

local function getPrimaryInstance(prop: Types.Prop | Types.DataModelProp): Types.DataModelProp
	local model: Types.DataModelProp
	if typeof(prop) == "table" then
		model = prop.Model
	else
		model = prop
	end

	local instance: Types.DataModelProp = model
	if model:IsDescendantOf(workspace.Corpses) then
		local foundModel = model:FindFirstAncestorOfClass("Model")
		if foundModel and foundModel:IsDescendantOf(workspace.Corpses) then
			instance = foundModel
		end
	end

	return instance
end

local function getPrimaryPart(prop: Types.Prop | Types.DataModelProp): BasePart?
	local model = getPrimaryInstance(prop)

	if model:IsA("Model") then
		return model.PrimaryPart
	end

	return model
end

local function isPropSmallEnough(part: BasePart): boolean
	local size = part.Size
	if part.AssemblyMass > 160 or (size.X * size.Y * size.Z) > 50 or size.X > 5 or size.Y > 5 or size.Z > 5 then
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

local function getControllerObject(prop: Types.DataModelProp): IntValue?
	local controllerObject = prop:FindFirstChild("MagnetoController")
	if not controllerObject or not controllerObject:IsA("IntValue") then
		return nil
	end
	
	return controllerObject
end

local function getController(prop: Types.DataModelProp): Player?
	local controllerObject = getControllerObject(prop)
	if not controllerObject then
		return nil
	end

	local player = Players:GetPlayerByUserId(controllerObject.Value)
	return player
end

local function onPropTouchedServer(prop: Types.MapProp, otherPart: BasePart, con: RBXScriptConnection): ()
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
		return con:Disconnect()
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

function module.SetLastHeldBy(prop: Types.MapProp, by: Player?): ()
	if not by then
		serverLastHeldBy[prop] = nil
	else
		serverLastHeldBy[prop] = {By = by, At = workspace:GetServerTimeNow()}
		if not serverTouchedConnections[prop] then
			local con: RBXScriptConnection
			con = prop.Model.Touched:Connect(function(otherPart)
				onPropTouchedServer(prop, otherPart, con)
			end)
			serverTouchedConnections[prop] = con

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

	if prop.Kind == "MapProp" and not serverTouchedConnections[prop] then
		module.SetLastHeldBy(prop, player)
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
end

local function canControl(prop: Types.Prop | Types.DataModelProp): boolean
	local controller = getController(getPrimaryInstance(prop))
	return not controller
end

local function isControlledBy(prop: Types.DataModelProp, player: Player): boolean
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

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	alignPosition.ReactionForceEnabled = false
	alignPosition.ApplyAtCenterOfMass = true
	alignPosition.Responsiveness = ALIGNMENT_RESPONSIVENESS
	alignPosition.MaxForce = part.AssemblyMass * ALIGNMENT_RESPONSIVENESS * 200

	alignPosition.Attachment0 = createOrFindAttachment(prop)
	alignPosition.Parent = prop

	currentGrabClient = alignPosition

	animate()
end

local function pushPropClient(prop: Types.DataModelProp): ()
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
	local LocalCharacter = require(ReplicatedStorage.LocalCharacter)
	local LocalRoundInfo = require(ReplicatedStorage.LocalRoundInfo)

	local char = LocalCharacter.Character()
	if not char then
		return nil
	end

	local map = LocalRoundInfo.Map()
	if not map then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char, map.Bounds}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	local result = workspace:Raycast(origin, direction * INTERACT_DISTANCE, params)
	if not result then
		return nil
	end

	local part = result.Instance :: BasePart

	if not part:IsDescendantOf(map.Props) and not part:IsDescendantOf(map.ItemSpawns) and not part:IsDescendantOf(map.AmmoSpawns) and not part:IsDescendantOf(workspace.Corpses) then
		return nil
	end

	return part
end

local function primaryFireClient(_, _, origin: Vector3, direction: Vector3): ()
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

local function isPartTouchingPart(part1: BasePart, part2: BasePart): boolean
	for _, v in workspace:GetPartsInPart(part1) do
		if v == part2 then
			return true
		end
	end

	return false
end

local preSimulationClient: (item: Types.AnyItem, dt: number) -> () = function(): ()
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

	local LocalCharacter = require(ReplicatedStorage.LocalCharacter)

	local char = LocalCharacter.Character()
	if not char then
		return
	end

	local leftFoot = char:FindFirstChild("LeftFoot")
	local rightFoot = char:FindFirstChild("RightFoot")

	if leftFoot and leftFoot:IsA("BasePart") then
		if isPartTouchingPart(leftFoot, part) then
			return stopControllingPropClient()
		end
	end

	if rightFoot and rightFoot:IsA("BasePart") then
		if isPartTouchingPart(rightFoot, part) then
			return stopControllingPropClient()
		end
	end

	currentGrabClient.Position = GetCentreRay(ALIGNMENT_DEPTH).Origin
end

local function getPropServer(participant: Types.Participant, origin: Vector3, direction: Vector3): Types.Prop?
	local map = participant.Round:GetMap()

	local char = participant:GetCharacter()
	if not char then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {map.Bounds, char}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	local result = workspace:Raycast(origin, direction * INTERACT_DISTANCE, params)
	if not result then
		return nil
	end

	local part = result.Instance :: BasePart

	local model: Types.DataModelProp? = part
	if part:IsDescendantOf(workspace.Corpses) then
		model = part:FindFirstAncestorOfClass("Model")
	end

	if not model then
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

	PreSimulationClient = preSimulationClient,

    PrimaryHint = "Push Prop",
    AlternateHint = "Grab Prop",
}

module.Item = item

return module