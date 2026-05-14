local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InteractableItem = require(ReplicatedStorage.API.Item.Presets.InteractableItem)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)

local Turtles = InteractableItem({
	Name = "Turtles",
	Description = "all your face are belong to us",
	IconContent = Content.none,

	ItemGroup = ItemGroups.RoleUtility,
	DropDisabled = true,

	Model = ReplicatedStorage.Assets.ItemModels.Turtles,
	HoldAnimation = Content.fromAssetId(103107994867562),

	Cost = 1,
	MaxStock = 1,

	PrimaryToggled = true,
	PrimaryHint = "Deploy Turtles",
}, true, false, nil, nil, 3)

return Turtles