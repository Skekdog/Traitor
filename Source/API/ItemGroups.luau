local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local ItemGroups = {}

ItemGroups.Secondary = {
	PreferredSlot = 2,
} :: Types.ItemGroup

ItemGroups.Primary = {
	PreferredSlot = 3,
} :: Types.ItemGroup

ItemGroups.Grenade = {
	PreferredSlot = 4,
} :: Types.ItemGroup

ItemGroups.RoleWeapon = {
	PreferredSlot = 7,
} :: Types.ItemGroup

ItemGroups.RoleUtility = {
	PreferredSlot = 8,
} :: Types.ItemGroup

return ItemGroups