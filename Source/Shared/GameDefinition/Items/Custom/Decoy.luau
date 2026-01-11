local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DNAScanner = require(script.Parent.DNAScanner)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local InteractableItem = require(ReplicatedStorage.API.ItemPresets.InteractableItem)

local Decoy = InteractableItem({
	Name = "Decoy",
    ItemGroup = ItemGroups.RoleUtility,
    DropDisabled = true,

    Cost = 1,
    MaxStock = 1,

    Description = "When placed, overrides your shown position on radars. Can be destroyed.",
    IconContent = Content.fromAssetId(96906503847712),

    AlternateToggled = true,
    AlternateHint = "Plant Decoy",
}, false, true, nil, function(interactable, _, weld, participant)
	local object = interactable.Model
	assert(object:IsA("BasePart"))

	weld.Enabled = false
	object.CFrame *= CFrame.new(0, 0, -object.Size.Z / 2)
	weld.Enabled = true

	interactable.Model:SetAttribute("Player", participant.Player.Name)
	DNAScanner.AddDNATrace(interactable, participant, nil, Content.fromAssetId(96906503847712), interactable.Model)
end)

return Decoy