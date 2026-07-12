local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local InteractableItem = require(ReplicatedStorage.API.Item.Presets.InteractableItem)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)

local DEPLOY_TIME = 5

local deploySound = Audio.MakeSound({
	Content = Content.fromAssetId(11956590),
	RolloffStart = 20,
	RolloffEnd = 30,
})

local Landmine = InteractableItem({
	Name = "Landmine",
	Description = "A great area denial tool. Exercise caution when placing.",
	IconContent = Content.fromAssetId(82684167883573),

	ItemGroup = ItemGroups.RoleUtility,
	DropDisabled = true,

	Model = ReplicatedStorage.Assets.ItemModels.Landmine,
	HoldAnimation = Content.fromAssetId(103107994867562),

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

	local model = GetPrimaryPart(prop.Model)
	task.delay(DEPLOY_TIME, function()
		if not model:IsDescendantOf(workspace) then
			return
		end

		Audio.PlayIn(deploySound, model, false, true)

		model.Touched:Connect(function(part)
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
end)

return table.freeze(Landmine)