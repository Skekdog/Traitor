local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local InteractableItem = require(ReplicatedStorage.API.Item.Presets.InteractableItem)

local DeathStation = InteractableItem({
	Name = "DeathStation",
    DisplayName = "Death Station",
    ItemGroup = ItemGroups.RoleUtility,

    Description = "Visually mimics a health station. Can be used by good guys to die.",
    IconContent = Content.fromAssetId(109445031317494),
    IsPixelIcon = true,

    Cost = 1,
    MaxStock = 1,

    PrimaryToggled = true,
    PrimaryHint = "Deploy Death Station",
}, true, false)

return table.freeze(DeathStation)