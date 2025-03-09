local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.RoundRule.Types)
local GetItemDefinition = require(script.Parent.GetItemDefinition)

local function OnHitClient(itemName: string, hitPart: BasePart?): ()
	local item = GetItemDefinition(itemName)
	if not item or item.Kind == "Item" then
		return
	end

	if not item.OnHitClient then
		return
	end

	item.OnHitClient(item :: Types.ItemDefinitionOnHitClient, hitPart)
end

return OnHitClient