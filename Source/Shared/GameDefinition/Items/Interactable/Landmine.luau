local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local InteractableItem = require(ReplicatedStorage.API.Item.Presets.InteractableItem)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)

local Landmine = InteractableItem({
	Name = "Landmine",
	Description = "An exquisite area denial tool. Exercise caution when placing.",
	IconContent = Content.fromAssetId(82684167883573),

	ItemGroup = ItemGroups.RoleUtility,
	DropDisabled = true,

	Model = ReplicatedStorage.Assets.ItemModels.Landmine,

	Cost = 1,
	MaxStock = 2,

	AlternateToggled = true,
	AlternateHint = "Plant Landmine",
}, false, true, nil, function(prop, result, weld, participant): ()
	local object = prop.Model
    assert(object:IsA("BasePart"))

    weld.Enabled = false
    object.CFrame *= CFrame.Angles(math.rad(-90), 0, 0)
	object.CFrame += result.Normal / 4
    weld.Enabled = true

	GetPrimaryPart(prop.Model).Touched:Connect(function(part)
		local otherCharacter = GetMapObject(part, "Character")
		if not otherCharacter then
			local otherPropModel = GetMapObject(part, "Prop")
			if not otherPropModel then
				return
			end
		end

		prop:TryTakeDamage({
			Attacker = prop.Extras.Participant,
			Amount = math.huge,
			Source = "Stomp",
		})
	end)
end)

return table.freeze(Landmine)