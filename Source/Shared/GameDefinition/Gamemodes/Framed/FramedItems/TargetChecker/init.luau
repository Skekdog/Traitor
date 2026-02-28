local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Types = require(ReplicatedStorage.API.Types)

local TargetChecker = {}

local function OnEquipClient(): ()
	PlaySound(9118027489)
end

local item: Types.ItemComponents = {
	Name = "TargetChecker",
	DisplayName = "Target Checker",

	Description = "Used to identify your target.",
	IconContent = Content.none,

	Model = ReplicatedStorage.Assets.Gamemode.Framed.Items.TargetChecker,
	HoldAnimation = Content.fromAssetId(122493302142724),

	ItemGroup = {
		PreferredSlot = 6,
	},

	DropDisabled = true,

	OnEquipClient = OnEquipClient,
}

TargetChecker.Item = item

return TargetChecker