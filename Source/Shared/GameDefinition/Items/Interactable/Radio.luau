local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local InteractableItem = require(ReplicatedStorage.API.Item.Presets.InteractableItem)
local DNAScanner = require(ReplicatedStorage.Shared.GameDefinition.Items.Custom.DNAScanner)

local Radio = InteractableItem({
	Name = "Radio",
    ItemGroup = ItemGroups.RoleUtility,
    DropDisabled = true,

    Description = "Remotely plays a sound to confuse nearby spies.",
    IconContent = Content.fromAssetId(128627317841330),

    Cost = 1,
    MaxStock = 1,

    PrimaryToggled = true,
    PrimaryHint = "Deploy Radio",
}, true, false, function(interactable, participant)
	interactable.Extras.Player = participant.Player
    DNAScanner.AddDNATrace(interactable, participant, nil, Content.fromAssetId(128627317841330), interactable.Model)
end)

return table.freeze(Radio)