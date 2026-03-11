local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Checks = require(ReplicatedStorage.API.Item.Behaviour.Checks)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Types = require(ReplicatedStorage.API.Types)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local GetRemote = require(ReplicatedStorage.API.GetRemote)

local Pigeon = {}

local recallRemote = GetRemote("Recall", script)

local MODEL = ReplicatedStorage.Assets.ItemModels.Pigeon

local ORBIT_SPEED = 0.5 * math.pi -- rad/s
local ORBIT_RADIUS = 10 -- well, studs

local RECALL_SPEED = 20
local FOLLOW_SPEED = 20
local CHARGE_SPEED = 50
local CLIMB_SPEED = 2

local SEARCH_RADIUS = 40

local CHARGE_DISTANCE = 10

local TARGET_HEIGHT = 7.5

type PigeonData = {
	Velocity: LinearVelocity,
	CurrentAngle: number,
	Pigeon: Types.MapObject,
	Round: Types.Round,
	Orientation: AlignOrientation,
	LaunchRole: Types.Role,
	Launcher: Types.Participant,
	DeployHeight: number,
	IsRecalling: boolean,
}

local pigeons: {PigeonData} = {}

local function updateRecall(data: PigeonData): ()
	local char = data.Launcher:GetCharacter()
	if not char then
		data.IsRecalling = false
		return
	end

	local root = char.PrimaryPart
	if not root then
		data.IsRecalling = false
		return
	end

	local part = GetPrimaryPart(data.Pigeon)

	data.Velocity.VectorVelocity = (root.Position - part.Position).Unit * RECALL_SPEED
	data.Orientation.CFrame = CFrame.lookAt(part.Position, root.Position)
end

local function updateOrbit(data: PigeonData, dt: number): ()
	local newAngle = (data.CurrentAngle + (dt * ORBIT_SPEED)) % (2 * math.pi)

	local part = GetPrimaryPart(data.Pigeon)

	local speed = (ORBIT_SPEED ^ 2) * ORBIT_RADIUS

	local mass = part.AssemblyMass -- this can't be a constant because it is incorrect due to the weld not being loaded
	local magnitude = mass * speed

	local speed_x = magnitude * math.sin(newAngle)
	local speed_z = magnitude * math.cos(newAngle)

	local velocity = Vector3.new(speed_x, if (data.DeployHeight + TARGET_HEIGHT) > part.Position.Y then CLIMB_SPEED else 0, speed_z)
	data.Velocity.VectorVelocity = velocity

	data.Orientation.CFrame = CFrame.lookAt(part.Position, part.Position + velocity.Unit)

	data.CurrentAngle = newAngle
end

local function scanForPlayers(data: PigeonData, dt: number): boolean
	local GetParticipant = require(ReplicatedStorage.API.GetParticipant)

	local origin = GetPrimaryPart(data.Pigeon).Position

	local params = OverlapParams.new()
	params.FilterDescendantsInstances = {workspace.Characters}
	params.FilterType = Enum.RaycastFilterType.Include

	local closestPart: BasePart?, closestDistance = nil, math.huge

	local foundParticipants: {Types.Participant} = {}
	for _, part in workspace:GetPartBoundsInRadius(origin, SEARCH_RADIUS, params) do
		if part.Name ~= "Head" then
			continue
		end

		local distance = (part.Position - origin).Magnitude
		if distance >= closestDistance then
			continue
		end

		local participant: Types.Participant? = GetParticipant(part) -- annotation needed because type-checker otherwise calls it too complex
		if not participant or table.find(foundParticipants, participant) then
			continue
		end

		if participant == data.Launcher or participant:GetRole():IsAlliedWith(data.LaunchRole) then
			continue
		end

		local canReach = Checks.RaycastStatic(data.Round:GetMap(), origin, part.Position, part)
		if not canReach then
			continue
		end

		closestDistance = distance
		closestPart = part

		table.insert(foundParticipants, participant)
	end

	if not closestPart then
		return false
	end

	local heightAlignedTarget = Vector3.new(closestPart.Position.X, origin.Y, closestPart.Position.Z)

	local isCharge = (heightAlignedTarget - origin).Magnitude < CHARGE_DISTANCE

	local direction = if isCharge then (heightAlignedTarget - origin).Unit else (closestPart.Position - origin).Unit

	data.Velocity.VectorVelocity = direction * if isCharge then CHARGE_SPEED else FOLLOW_SPEED
	data.Orientation.CFrame = CFrame.lookAlong(origin, direction)

	return true
end

RunService.PreSimulation:Connect(function(dt)
	for _, data in pigeons do
		if data.IsRecalling then
			updateRecall(data)
		end

		if not data.IsRecalling then -- updateRecall() might disable recalling
			if not scanForPlayers(data, dt) then
				updateOrbit(data, dt)
			end
		end
	end
end)

if RunService:IsClient() then
	local CustomActions = require(ReplicatedStorage.API.CustomActions)
	recallRemote.OnClientEvent:Connect(function(active: boolean): ()
		if not active then
			CustomActions.Unregister("Recall Pigeon")
			return
		end

		CustomActions.Register("Recall Pigeon", function()
			recallRemote:FireServer()
		end, 2)
	end)
else
	recallRemote.OnServerEvent:Connect(function(player)
		local GetParticipant = require(ReplicatedStorage.API.GetParticipant)
		local participant: Types.Participant? = GetParticipant(player)

		if not participant or not participant:IsAlive() then
			return
		end

		for _, pigeon in pigeons do
			if pigeon.Launcher == participant then
				pigeon.IsRecalling = true
				break
			end
		end
	end)
end

local function PrimaryFireServer(item: Types.Item, origin: Vector3, direction: Vector3, participant: Types.Participant, _): {string} | string?
	local Combat = require(ReplicatedStorage.API.Combat)
	local GetParticipant = require(ReplicatedStorage.API.GetParticipant)

	local model = (assert(item.Model) :: typeof(MODEL)):Clone()

	model.Attachment.Axis = Vector3.new(0, 0, -1)
	model.Attachment.SecondaryAxis = Vector3.new(0, 1, 0)

	model:RemoveTag("Item")
	model:RemoveTag("Prop")

	if not participant:TryThrowAssembly(model, 0, participant.Round:GetMap().Structure.Dynamic, origin, direction, nil, true) then
		return
	end

	participant:RemoveItem(item)

	local mass = model.AssemblyMass

	local velocity = Instance.new("LinearVelocity")
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.ForceLimitsEnabled = true
	velocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	velocity.MaxAxesForce = Vector3.new(mass * 20, mass * workspace.Gravity * 1.25, mass * 20)
	velocity.Attachment0 = model.Attachment
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = model

	local orientation = Instance.new("AlignOrientation")
	orientation.Attachment0 = model.Attachment
	orientation.AlignType = Enum.AlignType.AllAxes
	orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.MaxTorque = 7.5
	orientation.MaxAngularVelocity = 2.5
	orientation.Responsiveness = 50
	orientation.SecondaryAxis = Vector3.xAxis
	orientation.Parent = model

	GetPrimaryPart(model):SetNetworkOwner(nil)

	local launchRole = participant:GetRole()

	table.insert(pigeons, {
		Velocity = velocity,
		Pigeon = model :: BasePart,
		CurrentAngle = 0,
		Round = participant.Round,
		Orientation = orientation,
		LaunchRole = launchRole,
		Launcher = participant,
		DeployHeight = origin.Y,
		IsRecalling = false,
	})

	ForEachPart(model, function(part)
		part.Touched:Connect(function(otherPart)
			local target: Types.Participant? = GetParticipant(otherPart)
			if not target then
				return
			end

			if target == participant then
				model:Destroy()
				participant:AddItem(item)
				return
			end

			if target:GetRole():IsAlliedWith(launchRole) then
				return
			end

			model:Destroy()
			Combat.MakeExplosion({
				Attacker = participant,
				Damage = 100,
				FalloffStart = 10,
				FalloffEnd = 15,
				Position = GetPrimaryPart(model).Position,
			})
		end)
	end)

	recallRemote:FireClient(participant.Player, true)

	model.Destroying:Connect(function()
		recallRemote:FireClient(participant.Player, false)
	end)

	return nil
end

local item = Custom({
	Name = "Pigeon",
	Description = "Unmanned aerial bombing pigeon",
	IconContent = Content.none,

	Cost = 1,
	MaxStock = 1,

	DoNotShowInEquipmentList = true,
	ItemGroup = ItemGroups.RoleUtility,
	DropDisabled = true,

	Model = MODEL,

	PrimaryFireServer = PrimaryFireServer,
	PrimaryToggled = true,
})

Pigeon.Item = item

return Pigeon