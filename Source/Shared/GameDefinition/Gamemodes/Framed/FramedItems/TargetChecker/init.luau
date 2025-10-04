local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Types = require(ReplicatedStorage.API.Types)

local TargetChecker = {}

local function OnEquipClient(): ()
	PlaySound(9118027489)
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "TargetChecker",
	DisplayName = "Target Checker",

	Model = script.TargetChecker,
	HoldAnimation = "rbxassetid://122493302142724",

	ItemGroup = {
		PreferredSlot = 1,
	},

	OnEquipClient = OnEquipClient,
}

TargetChecker.Item = item

return TargetChecker