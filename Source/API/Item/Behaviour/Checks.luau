local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local Checks = {}

local STATIC_OBSCURE_DISTANCE = 0.05

local MAX_TARGET_DISTANCE = 10

local MAX_SHOOTER_DISTANCE = 15

function Checks.Ammo(item: Types.Item): boolean
	return if item.Ammo then item.Ammo > 0 else true
end

function Checks.Scoped(item: Types.Item, isScoped: boolean): ()
	return if item.IsScopeRequired then isScoped else true
end

function Checks.Reloading(item: Types.Item): boolean
	return item.IsReloading ~= true
end

function Checks.ActionEnabled(item: Types.Item, action: "Primary" | "Alternate"): boolean
	return if action == "Primary" then item.PrimaryDisabled ~= true else item.AlternateDisabled ~= true
end

function Checks.Alive(item: Types.Item, health: number): boolean
	return health > 0
end

function Checks.GamePhase(item: Types.Item, phase: Types.Phase): boolean
	return if item.PregameDisable and phase == "Preparing" or phase == "Waiting" then false else true
end

function Checks.Interval(item: Types.Item, action: "Primary" | "Alternate"): boolean
	if action == "Primary" then
		return (item.PrimaryLastUse or 0) + (item.PrimaryInterval or 0) < os.clock()
	else
		return (item.AlternateLastUse or 0) + (item.AlternateInterval or 0) < os.clock()
	end
end

function Checks.TargetDistance(item: Types.Item, origin: Vector3, destination: Vector3, target: BasePart?): boolean
	if target and (target.Position - destination).Magnitude > MAX_TARGET_DISTANCE then
		return false
	end

	if item.MaxDistance and (destination - origin).Magnitude > (item.MaxDistance + 1) then
		return false
	end

	return true
end

function Checks.OriginDistance(item: Types.Item, origin: Vector3, character: Model): boolean
	local head = character:FindFirstChild("Head")
	if not head then
		return false
	end

	if not head:IsA("BasePart") or (head.Position - origin).Magnitude > (MAX_SHOOTER_DISTANCE + head.AssemblyLinearVelocity.Magnitude) then
		return false
	end

	return true
end

local staticParams = RaycastParams.new()
staticParams.CollisionGroup = "WeaponHitTargets"
staticParams.IgnoreWater = true

function Checks.RaycastStatic(map: Types.Map, origin: Vector3, destination: Vector3, target: BasePart?): boolean
	if not target then
		return true
	end

	staticParams.IncludeInstances = {map.Structure.Static}

	-- We need to check the distance between the hit target and the actual intended target.
	-- Reason being, some maps unfortunately feature Z-fighting, leading to hits being rejected as they were "obscured" by a part in the same exact place.
	-- We do still set the actual target as the hit result though

	local result = workspace:Raycast(origin, destination - origin, staticParams)
	if result and result.Instance ~= target then
		if (result.Position - destination).Magnitude > STATIC_OBSCURE_DISTANCE then
			return false
		end
	end

	return true
end

return table.freeze(Checks)