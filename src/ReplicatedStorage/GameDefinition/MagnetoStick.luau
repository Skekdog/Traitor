local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetCentreRay = require(ReplicatedStorage.GetCentreRay)
local Types = require(ReplicatedStorage.RoundRule.Types)

local INTERACT_DISTANCE = 7.5
local MAX_DISTANCE = 15

local ALIGNMENT_POWER_PER_UNIT_MASS = 2500
local ALIGNMENT_DAMPING_PER_UNIT_MASS = 50
local ALIGNMENT_DEPTH = 6

local function models(name: string): BasePart
    return ReplicatedStorage:WaitForChild("WeaponModels"):WaitForChild(name) :: BasePart
end

local serverGrabbedProps: {[Types.Participant]: Types.Prop?} = {}
local currentGrabClient: BodyPosition?

local function animate(): ()
	local LocalAnimation = require(ReplicatedStorage.LocalAnimation)
	local ViewmodelModule = require(ReplicatedStorage.ViewmodelModule)

	LocalAnimation.TryPlayAnimation(13269497293, "Magneto")
	ViewmodelModule.PlayAnimation("rbxassetid://13269497293", "Magneto")
end

local function getPrimaryPart(prop: Types.Prop | Types.DataModelProp): BasePart?
	local model: Types.DataModelProp
	if typeof(prop) == "table" then
		model = prop.Model
	else
		model = prop
	end

	if model:IsA("Model") then
		return model.PrimaryPart
	end

	return model
end

local function isPropSmallEnough(prop: Types.DataModelProp): boolean
	local part = getPrimaryPart(prop)
	if not part then
		return false
	end

	local size = part.Size
	if part.AssemblyMass > 160 or (size.X * size.Y * size.Z) > 50 or size.X > 5 or size.Y > 5 or size.Z > 5 then
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

local function getControllerObject(part: BasePart): IntValue?
	local controllerObject = part:FindFirstChild("MagnetoController")
	if not controllerObject or not controllerObject:IsA("IntValue") then
		return nil
	end
	
	return controllerObject
end

local function getController(part: BasePart): Player?
	local controllerObject = getControllerObject(part)
	if not controllerObject then
		return nil
	end

	local player = Players:GetPlayerByUserId(controllerObject.Value)
	return player
end

local function stopControllingPropClient(): ()
	if not currentGrabClient then
		return
	end

	currentGrabClient:Destroy()
	currentGrabClient = nil

	animate()
end

local function stopControllingPropServer(participant: Types.Participant): ()
	local prop = serverGrabbedProps[participant]
	if not prop then
		return
	end

	local part = getPrimaryPart(prop)
	if not part then
		return
	end

	local controllerObject = getControllerObject(part)
	if controllerObject then
		controllerObject.Value = 0
	end

	setNetworkOwnerOfPart(part, "Auto")

	serverGrabbedProps[participant] = nil
end

local function canControl(prop: Types.Prop | Types.DataModelProp): boolean
	local part = getPrimaryPart(prop)
	if not part then
		return false
	end

	local controller = getController(part)
	return not controller
end

local function isClientControlling(prop: Types.DataModelProp): boolean
	local part = getPrimaryPart(prop)
	if not part then
		return false
	end

	local controller = getController(part)
	return controller == Players.LocalPlayer
end

local function startControllingPropClient(prop: Types.DataModelProp): ()
	if not canControl(prop) then
		return
	end

	local part = getPrimaryPart(prop)
	if not part then
		return
	end

	if not isPropSmallEnough(part) then
		return
	end

	local targetPower = part.AssemblyMass * ALIGNMENT_POWER_PER_UNIT_MASS

	local alignPosition = Instance.new("BodyPosition")
	alignPosition.P = targetPower
	alignPosition.MaxForce = Vector3.one * targetPower / 3
	alignPosition.D = ALIGNMENT_DAMPING_PER_UNIT_MASS * part.AssemblyMass
	alignPosition.Parent = getPrimaryPart(prop)
	currentGrabClient = alignPosition

	animate()
end

local function pushPropClient(prop: Types.DataModelProp): ()
	if not canControl(prop) then
		return
	end
	
	local part = getPrimaryPart(prop)
	if not part then
		return
	end

	local centreRay = GetCentreRay()
	part:ApplyImpulseAtPosition(centreRay.Direction * ((ALIGNMENT_POWER_PER_UNIT_MASS * part.AssemblyMass) / 500), part:GetClosestPointOnSurface(centreRay.Origin))
end

local function getPropClient(origin: Vector3, direction: Vector3): Types.DataModelProp?
	local LocalCharacter = require(ReplicatedStorage.LocalCharacter)
	local LocalRoundInfo = require(ReplicatedStorage.LocalRoundInfo)

	local char = LocalCharacter.GetCharacter()
	if not char then
		return nil
	end

	local map = LocalRoundInfo.GetMap()
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

	local model: Types.DataModelProp? = part
	if part:IsDescendantOf(workspace.Corpses) then
		model = part:FindFirstAncestorOfClass("Model")
	end

	if not model then
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
	stopControllingPropClient()

	local prop = getPropClient(origin, direction)
	if not prop then
		return
	end

	if not isClientControlling(prop) then
		startControllingPropClient(prop)
	end
end

local function onUnequipClient(): ()
	stopControllingPropClient()
end

local function onUnequipServer(_, participant: Types.Participant): ()
	stopControllingPropServer(participant)
end

local function isPartTouchingPart(part1: BasePart, part2: BasePart): boolean
	for _, v in workspace:GetPartsInPart(part1) do
		if v == part2 then
			return true
		end
	end

	return false
end

local preSimulationClient: (item: Types.Item, dt: number) -> () = function(): ()
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

	local char = LocalCharacter.GetCharacter()
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
		return
	end

	local part = getPrimaryPart(prop)
	if not part then
		return
	end

	if not canControl(prop) then
		return stopControllingPropServer(participant)
	end

	stopControllingPropServer(participant)

	if mode == "Alternate" then
		if not isPropSmallEnough(part) then
			return
		end

		local controllerObject = getControllerObject(part)
		if not controllerObject then
			local newObject = Instance.new("IntValue")
			newObject.Name = "MagnetoController"
			newObject.Parent = part

			controllerObject = newObject
		end

		assert(controllerObject)
		controllerObject.Value = participant.Player.UserId

		serverGrabbedProps[participant] = prop
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

return item