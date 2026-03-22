local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local Mirror = {}

local item: Types.ItemComponents = {
	Name = "Mirror",

	Description = "Shows your face.",
	IconContent = Content.none,

	Model = ReplicatedStorage.Assets.Gamemode.Framed.Items.Mirror,
	HoldAnimation = Content.fromAssetId(136425139325295),

	ItemGroup = {
		PreferredSlot = 9,
	},

	DropDisabled = true,
}

Mirror.Item = item

return table.freeze(Mirror)