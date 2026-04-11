local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local Types = require(ReplicatedStorage.API.Types)

local TargetChecker = {}

local EQUIP_SOUND = Audio.MakeSound({
	Content = Content.fromAssetId(9118027489),
})

local function OnEquipClient(): ()
	Audio.Play2D(EQUIP_SOUND)
end

local item: Types.ItemComponents = {
	Name = "FakeTargetChecker",
	DisplayName = "Fake Target Checker",

	Description = "Blends in with the framed.",
	IconContent = Content.none,

	Model = ReplicatedStorage.Assets.Gamemode.Framed.Items.FakeTargetChecker,
	HoldAnimation = Content.fromAssetId(122493302142724),

	ItemGroup = {
		PreferredSlot = 6,
	},

	OnEquipClient = OnEquipClient,

	DropDisabled = true,
}

TargetChecker.Item = item

return table.freeze(TargetChecker)