local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local InteractableItem = require(ReplicatedStorage.API.Item.Presets.InteractableItem)

local C4 = InteractableItem({
	Name = "C4",
    ItemGroup = ItemGroups.RoleWeapon,

    IsSuspicious = true,

    Description = "Explodes in a massive radius after a set timer.",
    IconContent = Content.fromAssetId(17229908151),

	Model = ReplicatedStorage.Assets.InteractableModels.C4,
    HoldAnimation = Content.fromAssetId(92236433436790),

    Cost = 1,
    MaxStock = 2,

    PrimaryHint = "Throw C4",
    AlternateHint = "Plant C4",

    PrimaryToggled = true,
    AlternateToggled = true,
}, true, true, nil, function(interactable, result, weld)
	local object = interactable.Model
    assert(object:IsA("BasePart"))

    weld.Enabled = false
    object.CFrame *= CFrame.Angles(math.rad(-90), 0, 0)
	object.CFrame += result.Normal / 4
    weld.Enabled = true
end)

return table.freeze(C4)