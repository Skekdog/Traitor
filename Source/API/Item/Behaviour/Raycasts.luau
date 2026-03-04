local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetCentreRay = require(ReplicatedStorage.Shared.Camera.GetCentreRay)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local BehaviourTypes = require(script.Parent.BehaviourTypes)
local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)

local Raycasts = {}

local random = Random.new(workspace:GetServerTimeNow())
function Raycasts.GetRaycastDirection(direction: Vector3, spread: number): Vector3
	local spreadVector = Vector3.new(random:NextNumber(-spread, spread), random:NextNumber(-spread, spread), random:NextNumber(-spread, spread))
	return (direction + spreadVector).Unit
end

function Raycasts.DeriveTargetPosition(origin: Vector3, direction: Vector3, range: number): Vector3
	return origin + (direction.Unit * range)
end
function Raycasts.GetDefaultRaycastParams(char: Instance): RaycastParams
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	return params
end

function Raycasts.GetOrigin(): Vector3
	local head = LocalCharacter.Head()
	if not head then
		return Vector3.zero
	end

	return head.Position
end

function Raycasts.GetDirection(): Vector3
	return GetCentreRay().Direction
end


function Raycasts.Hitscan(
	params: RaycastParams,
	origin: Vector3,
	direction: Vector3,
	range: number,
	checkInitialOverlap: boolean?,
	fallbackToBlockcast: boolean?
): BehaviourTypes.HitscanResult
	local parts: {BasePart}?
	if checkInitialOverlap then
		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = params.FilterDescendantsInstances
		overlapParams.FilterType = params.FilterType
		overlapParams.CollisionGroup = params.CollisionGroup

		local boundPart = CreateEmptyPart(workspace.CurrentCamera.CFrame)
		boundPart.Size = Vector3.new(0.1, 0.1, 0.1)
		parts = workspace:GetPartsInPart(boundPart, overlapParams)
	end

	direction *= range
	local result = workspace:Raycast(origin, direction, params)

	if not result and fallbackToBlockcast then
		result = workspace:Blockcast(CFrame.new(origin), Vector3.one * 1.5, direction, params)
	end

	local part = if result then result.Instance else if parts and parts[1] then parts[1] else nil

	local position =
		if result then
			result.Position
		elseif part then
			part:GetClosestPointOnSurface(origin)
		else
			Raycasts.DeriveTargetPosition(origin, direction, range)

	local normal = if result then result.Normal else (origin - position).Unit
	local relativeCFrame = if part then part.CFrame:ToObjectSpace(CFrame.new(position)) else nil

	if part and relativeCFrame then
		return {
			Hit = {
				Part = part,
				Normal = normal,
				RelativeCFrame = relativeCFrame,
			},
			Position = position,
		}
	end

	return {
		Position = position,
	}
end

return Raycasts