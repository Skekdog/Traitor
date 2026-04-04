local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetCentreRay = require(ReplicatedStorage.Shared.Camera.GetCentreRay)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local BehaviourTypes = require(script.Parent.BehaviourTypes)
local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)
local GetMapObjectWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapObjectWithTag)

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

local function sortParts(part1: BasePart, part2: BasePart): boolean
	if GetMapObjectWithTag(part1, "Character") and not GetMapObjectWithTag(part2, "Character") then
		return true
	elseif GetMapObjectWithTag(part1, "Interactable") and not GetMapObjectWithTag(part2, "Interactable") then
		return true
	elseif GetMapObjectWithTag(part1, "Prop") and not GetMapObjectWithTag(part2, "Prop") then
		return true
	else
		return false
	end
end

local function createVisualiser(cframe: CFrame, size: Vector3, colour: Color3): ()
	local part = CreateEmptyPart(cframe)
	part.Size = size

	local highlight = Instance.new("Highlight")

	highlight.FillColor = colour
	highlight.FillTransparency = 0

	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0

	highlight.Parent = part

	part.Transparency = 0
	part.Parent = workspace.Projectiles

	task.delay(5, part.Destroy, part)
end

local function visualiseRay(origin: Vector3, destination: Vector3): ()
	local cframe = CFrame.lookAt((origin + destination) / 2, destination)

	local distance = (origin - destination).Magnitude
    local half = distance / 2

	local size = Vector3.new(0.05, 0.05, half)

	createVisualiser(cframe, size, Color3.new(0, 0, 1))
end

function Raycasts.Hitscan(
	params: RaycastParams,
	origin: Vector3,
	direction: Vector3,
	range: number,
	checkInitialOverlap: boolean?,
	fallbackToBlockcast: boolean?,
	visualiseCasts: boolean?
): BehaviourTypes.HitscanResult
	direction *= range
	local result = workspace:Raycast(origin, direction, params)

	if visualiseCasts then
		visualiseRay(origin, if result then result.Position else Raycasts.DeriveTargetPosition(origin, direction, 1))
	end

	if not result and fallbackToBlockcast then
		local cframe = CFrame.new(origin)
		local size = Vector3.one * 1.5

		result = workspace:Blockcast(cframe, size, direction, params)
	end

	local parts: {BasePart}?
	if not result and checkInitialOverlap then
		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = params.FilterDescendantsInstances
		overlapParams.FilterType = params.FilterType
		overlapParams.CollisionGroup = params.CollisionGroup

		local cframe = workspace.CurrentCamera.CFrame
		local size = Vector3.new(0.1, 0.1, 0.1)

		local boundPart = CreateEmptyPart(cframe)
		boundPart.Size = size

		local foundParts = workspace:GetPartsInPart(boundPart, overlapParams)
		parts = foundParts

		table.sort(foundParts, sortParts)

		if visualiseCasts then
			createVisualiser(cframe, size, Color3.new(1, 0, 0))
		end
	end

	local part = if result then result.Instance else if parts and parts[1] then parts[1] else nil

	local position =
		if result then
			result.Position
		elseif part then
			part:GetClosestPointOnSurface(origin)
		else
			Raycasts.DeriveTargetPosition(origin, direction, 1)

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

return table.freeze(Raycasts)