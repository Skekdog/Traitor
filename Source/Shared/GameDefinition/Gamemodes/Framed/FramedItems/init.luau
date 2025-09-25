local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local Items: {[string]: Types.ItemDefinition} = {}

for _, v in script:GetChildren() do
	if v:IsA("ModuleScript") then
		local itemModule = (require)(v)
		if itemModule and itemModule.Item then
			Items[v.Name] = itemModule.Item
		end
	end
end

return Items