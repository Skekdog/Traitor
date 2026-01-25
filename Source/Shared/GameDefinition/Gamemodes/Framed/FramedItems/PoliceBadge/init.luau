local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local PoliceBadge = {}

local item: Types.ItemComponents = {
	Name = "PoliceBadge",
	DisplayName = "Badge",

	Description = '"This badge... it proves that I am a police officer."',
	IconContent = Content.none,

	Model = script.PoliceBadge,
	HoldAnimation = Content.fromAssetId(76200494560650),

	ItemGroup = {
		PreferredSlot = 6,
	},

	DropDisabled = true,
}

PoliceBadge.Item = item

return PoliceBadge