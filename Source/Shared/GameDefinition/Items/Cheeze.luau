local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
local ItemGroups = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemGroups)

local Cheeze = {}

local HEAL_AMOUNT = 90
local COOLDOWN = 30

local function PrimaryFireServer(): ()

end

local function PrimaryFireClient(): ()

end

local function AlternateFireServer(): ()

end

local definition: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "Cheeze",
	Description = "Can be consumed to instantly heal, or thrown on the ground to allow others to heal.",
	Icon = "",

	CreditCost = 2,
	MaxStock = 1,

	ItemGroup = ItemGroups.RoleUtility,
}

Cheeze.Item = definition

return Cheeze