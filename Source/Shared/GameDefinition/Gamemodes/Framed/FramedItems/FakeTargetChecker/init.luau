local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Types = require(ReplicatedStorage.API.Types)

local TargetChecker = {}

local function OnEquipClient(): ()
	PlaySound(9118027489)
end

local item: Types.ItemComponents = {
	Name = "FakeTargetChecker",
	DisplayName = "Fake Target Checker",

	Description = "Blends in with the framed.",
	IconContent = Content.none,

	Model = script.FakeTargetChecker,
	HoldAnimation = Content.fromAssetId(122493302142724),

	ItemGroup = {
		PreferredSlot = 6,
	},

	OnEquipClient = OnEquipClient,
}

TargetChecker.Item = item

return TargetChecker