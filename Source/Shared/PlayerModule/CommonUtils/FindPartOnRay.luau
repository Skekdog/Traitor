
local FindPartOnRay = {}

function FindPartOnRay.Including(ray: Ray, include: {Instance}, ignoreWater: boolean?): (BasePart?, Vector3?, Vector3?, Enum.Material?)
	local params = RaycastParams.new()

	params.IgnoreWater = ignoreWater or false
	params.FilterDescendantsInstances = include
	params.FilterType = Enum.RaycastFilterType.Include

	local result = workspace:Raycast(ray.Origin, ray.Direction)

	if result then
		return result.Instance, result.Position, result.Normal, result.Material
	else
		return nil, nil, nil, nil
	end
end

function FindPartOnRay.Excluding(ray: Ray, exclude: {Instance}, terrainCellsAreCubes: boolean?, ignoreWater: boolean?): (BasePart?, Vector3?, Vector3?, Enum.Material?)
	local params = RaycastParams.new()

	params.IgnoreWater = ignoreWater or false
	params.FilterDescendantsInstances = exclude
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(ray.Origin, ray.Direction, params)

	if result then
		return result.Instance, result.Position, result.Normal, result.Material
	else
		return nil, nil, nil, nil
	end
end

return FindPartOnRay