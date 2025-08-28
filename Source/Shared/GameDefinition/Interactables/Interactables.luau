local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local interactables: {[string]: Types.InteractableDefinition} = {}

for _, v in script.Parent:GetChildren() do
	if v:IsA("ModuleScript") and v ~= script then
		local result = (require)(v)
		if result.Interactable then
			result = result.Interactable
		end
		interactables[v.Name] = result
	end
end

return interactables