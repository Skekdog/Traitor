local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local InteractableItem = require(ReplicatedStorage.API.Item.Presets.InteractableItem)
local DNAScanner = require(ReplicatedStorage.Shared.GameDefinition.Items.Custom.DNAScanner)

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
}, true, false, function(interactable, participant)
	interactable.Extras.Owner = participant
    DNAScanner.AddDNATrace(interactable, participant, nil, Content.fromAssetId(93284379186217), interactable.Model)
end)

return DeathStation