local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local InteractableItem = require(ReplicatedStorage.API.ItemPresets.InteractableItem)

local Visualiser = InteractableItem({
	Name = "Visualiser",
    ItemGroup = ItemGroups.RoleUtility,

    Description = "Recreates the scene of a player's murder, if they were killed by bullets.",
    IconContent = Content.fromAssetId(11817043651),

    Cost = 1,
    MaxStock = 1,

    PrimaryToggled = true,
    PrimaryHint = "Deploy Visualiser",
}, true, false, function(interactable, participant)
	interactable.Extras.Player = participant.Player
end)

return Visualiser