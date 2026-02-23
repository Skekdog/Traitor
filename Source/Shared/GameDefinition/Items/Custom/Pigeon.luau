local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)

local Pigeon = {}

local item = Custom({
	Name = "Pigeon",
	Description = "Unmanned aerial bombing pigeon",
	IconContent = Content.none,

	Cost = 1,
	MaxStock = 1,

	DoNotShowInEquipmentList = true,
	ItemGroup = ItemGroups.RoleUtility,
	DropDisabled = true,

	Model = ReplicatedStorage.Assets.ItemModels.Pigeon,
})

Pigeon.Item = item

return Pigeon