local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local Mirror = {}

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "Mirror",

	Model = script.Mirror,
	HoldAnimation = "rbxassetid://136425139325295",

	Slot = 6,
}

Mirror.Item = item

return Mirror