local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Types = require(ReplicatedStorage.API.Types)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)

local Pigeon = {}

local MODEL = ReplicatedStorage.Assets.ItemModels.Pigeon

local ORBIT_SPEED = 0.5 * math.pi -- rad/s
local ORBIT_RADIUS = 10 -- well, studs

local velocities: {[LinearVelocity]: {
	CurrentAngle: number,
}} = {}

RunService.PreSimulation:Connect(function(dt)
	for velocity, data in velocities do
		local newAngle = (data.CurrentAngle + (dt * ORBIT_SPEED)) % (2 * math.pi)

		local speed = (ORBIT_SPEED ^ 2) * ORBIT_RADIUS

		local mass = GetPrimaryPart(velocity.Parent :: Types.MapObject).AssemblyMass -- this can't be a constant because it is incorrect due to the weld not being loaded
		local magnitude = mass * speed

		local speed_x = magnitude * math.sin(newAngle)
		local speed_z = magnitude * math.cos(newAngle)

		velocity.VectorVelocity = Vector3.new(speed_x, 0, speed_z)

		data.CurrentAngle = newAngle
	end
end)

local function PrimaryFireServer(item: Types.Item, origin: Vector3, direction: Vector3, participant: Types.Participant, _): {string} | string?
	local model = assert(item.Model) :: typeof(MODEL)
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

	velocities[velocity] = {
		CurrentAngle = 0,
	}

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