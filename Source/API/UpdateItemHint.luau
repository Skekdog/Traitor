local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemHint = require(ReplicatedStorage.Shared.Controls.ItemHint)
local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)
local Types = require(script.Parent.Types)

local function UpdateItemHint(item: Types.Item, fire: "primary" | "alternate", newText: string?): ()
	if fire == "primary" then
		item.PrimaryHint = newText
	else
		item.AlternateHint = newText
	end

	local currentItem = ClientInventory.EquippedItem()
	if currentItem == item then
		print("changed to", item.PrimaryHint)
		ItemHint(item.PrimaryHint, item.AlternateHint)
	end
end

return UpdateItemHint