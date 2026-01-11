local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetItemDefinition = require(ReplicatedStorage.Shared.LocalState.GetItemDefinition)

local function OnHitClient(itemName: string, hitPart: BasePart?): ()
	local item = GetItemDefinition(itemName)
	if not item then
		return
	end

	if not item.OnHitClient then
		return
	end

	item.OnHitClient(hitPart)
end

ReplicatedStorage.Shared.RoundRule.Remotes.RunOnHitClient.OnClientEvent:Connect(OnHitClient)

return OnHitClient