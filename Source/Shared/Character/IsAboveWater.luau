local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function IsAboveWater(map: Types.Map, root: BasePart, distance: number): boolean
	local params = RaycastParams.new()
    params.RespectCanCollide = false
    params.IgnoreWater = false
    params.FilterDescendantsInstances = {root.Parent :: Model}
    params.FilterType = Enum.RaycastFilterType.Exclude

    -- The landed state often triggers really early so we do need to raycast quite far down. Testing on the Test map shows that -7.5 should suffice but I'll go -10 to be sure
    local result = workspace:Raycast(root.Position, Vector3.new(0, -distance, 0), params)
    if not result then
        return false
    end

    return (result.Material == Enum.Material.Water) or (result.Instance.Name == "! Water" and result.Instance:IsDescendantOf(map.StaticMap))
end

return IsAboveWater