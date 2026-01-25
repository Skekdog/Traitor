local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local InteractableItem = require(ReplicatedStorage.API.Item.Presets.InteractableItem)

local HealthStation = InteractableItem({
	Name = "HealthStation",
    DisplayName = "Health Station",
    ItemGroup = ItemGroups.RoleUtility,

    Description = "Can be used by anyone to restore health, with a slow recharge.",
    IconContent = Content.fromAssetId(93284379186217),
    IsPixelIcon = true,

    Cost = 1,
    MaxStock = 1,

    PrimaryToggled = true,
    PrimaryHint = "Deploy Health Station",
}, true, false)

return HealthStation