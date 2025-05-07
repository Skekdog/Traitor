local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetItemDefinition = require(ReplicatedStorage.Shared.LocalState.GetItemDefinition)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

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

ReplicatedStorage.Shared.RoundRule.Remotes.RunOnHitClient.OnClientEvent:Connect(OnHitClient)

return OnHitClient