local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local Checks = require(ReplicatedStorage.API.Item.Behaviour.Checks)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Types = require(ReplicatedStorage.API.Types)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)

local Pigeon = {}

local MODEL = ReplicatedStorage.Assets.ItemModels.Pigeon

local ORBIT_SPEED = 0.5 * math.pi -- rad/s
local ORBIT_RADIUS = 10 -- well, studs

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
}

local pigeons: {PigeonData} = {}

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

	data.Orientation.LookAtPosition = (part.Position + velocity).Unit

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

	local isCharge = (closestPart.Position * Vector3.new(1, 0, 1) - origin * Vector3.new(1, 0, 1)).Magnitude < CHARGE_DISTANCE

	local direction = (closestPart.Position - origin).Unit

	local velocity = if isCharge then direction else direction * Vector3.new(1, 0, 1)

	data.Velocity.VectorVelocity = velocity * if isCharge then CHARGE_SPEED else FOLLOW_SPEED
	data.Orientation.LookAtPosition = closestPart.Position

	return true
end

RunService.PreSimulation:Connect(function(dt)
	for _, data in pigeons do
		if not scanForPlayers(data, dt) then
			updateOrbit(data, dt)
		end
	end
end)

local function PrimaryFireServer(item: Types.Item, origin: Vector3, direction: Vector3, participant: Types.Participant, _): {string} | string?
	local Combat = require(ReplicatedStorage.API.Combat)

	local model = (assert(item.Model) :: typeof(MODEL)):Clone()

	model:RemoveTag("Item")
	model:RemoveTag("Prop")

	if not participant:TryThrowAssembly(model, 0, workspace.Projectiles, origin, direction, nil, true) then
		return
	end

	participant:RemoveItem(item)

	local mass = model.AssemblyMass

	local velocity = Instance.new("LinearVelocity")
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.ForceLimitsEnabled = true
	velocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	velocity.MaxAxesForce = Vector3.new(mass * 30, mass * workspace.Gravity * 1.5, mass * 30)
	velocity.Attachment0 = model.Attachment
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = model

	local orientation = Instance.new("AlignOrientation")
	orientation.Attachment0 = model.Attachment
	orientation.AlignType = Enum.AlignType.PrimaryAxisLookAt
	orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.MaxTorque = 2000
	orientation.MaxAngularVelocity = 10
	orientation.Parent = model

	GetPrimaryPart(model):SetNetworkOwner(nil)

	task.wait(5)

	table.insert(pigeons, {
		Velocity = velocity,
		Pigeon = model :: BasePart,
		CurrentAngle = 0,
		Round = participant.Round,
		Orientation = orientation,
		LaunchRole = participant:GetRole(),
		Launcher = participant,
		DeployHeight = origin.Y,
	})

	ForEachPart(model, function(part)
		part.Touched:Connect(function(otherPart)
			if GetMapObject(otherPart, "Character") then
				model:Destroy()
				Combat.MakeExplosion({
					Attacker = participant,
					Damage = 100,
					FalloffStart = 10,
					FalloffEnd = 15,
					Position = GetPrimaryPart(model).Position,
				})
			end
		end)
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