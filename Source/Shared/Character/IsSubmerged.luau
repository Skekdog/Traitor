
local function IsSubmerged(humanoid: Humanoid, at: Vector3, params: RaycastParams): boolean
	if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
		return false
	end

	local result = workspace:Raycast(at, Vector3.new(0, -6, 0), params)

	if not result then
		-- If we are underwater, then raycasting returns nothing as the ray is starting in the water object
		return true
	elseif result.Instance == workspace.Terrain and result.Material ~= Enum.Material.Water then
		-- If we hit something and it isn't water then we are at the sea floor
		return true
	end

	return false
end

return IsSubmerged