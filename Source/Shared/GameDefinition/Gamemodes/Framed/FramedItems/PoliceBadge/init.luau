local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local PoliceBadge = {}

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "PoliceBadge",
	DisplayName = "Badge",

	Model = script.PoliceBadge,
	HoldAnimation = "rbxassetid://76200494560650",

	Slot = 6,
}

PoliceBadge.Item = item

return PoliceBadge