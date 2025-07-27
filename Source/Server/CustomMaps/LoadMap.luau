local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local Map: {ValidateDefinition: (any) -> Types.MapDefinition} = script.Parent.GetMapModule:Invoke()

local function LoadMap(assetId: number): string | ModuleScript
	local successRequire: boolean, resultRequire: unknown = pcall(function()
		return (require)(assetId)
	end)

	if not successRequire then
		return 'Failed to load map: ' .. tostring(resultRequire)
	end

	if typeof(resultRequire) ~= "Instance" then
		return 'Invalid MainModule, must return "Map" ModuleScript.'
	end

	if not resultRequire:IsA("ModuleScript") then
		return 'Invalid MainModule, must return "Map" ModuleScript.'
	end

	local successMap: boolean, resultMap: unknown = pcall(function()
		return (require)(resultRequire)
	end)

	if not successMap then
		print(resultRequire)
		return 'Failed to load map: ' .. tostring(resultMap)
	end

	local _: boolean, map: Types.MapDefinition | string = pcall(function()
		return Map.ValidateDefinition(resultMap)
	end)

	if typeof(map) == "string" then
		return 'Invalid MapDefinition: ' .. map
	end

	resultRequire.Sandboxed = true
	resultRequire.Capabilities = SecurityCapabilities.fromCurrent():Remove(Enum.SecurityCapability.CapabilityControl)

	resultRequire.Name = map.Name

	return resultRequire
end

return LoadMap