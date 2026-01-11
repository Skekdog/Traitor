local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local Item = {}

type ItemInteractable = Types.Interactable & {
	Extras: {
		Item: Types.Item,
		[any]: nil,
	}
}

local definition: Types.InteractableDefinition = {
	Name = "Item",
	DisplayName = "",
	InteractionRange = 7.5,
	IsContinuousInteraction = false,

	DefaultHintText = "Grab",

	OnLoadServer = function(interactable: ItemInteractable): ()
		assert(interactable.Round)
		interactable.Extras.Item = interactable.Round:GetItem(interactable.Model) or error("Item not found")
	end,

	OnInteractServer = function(interactable: ItemInteractable, participant: Types.Participant): ()
		local foundItem = participant:GetItemOccupyingGroup(interactable.Extras.Item.Definition.ItemGroup)
		if foundItem then
			if (foundItem.UnequipDisabled or foundItem.DropDisabled) and not interactable.Model:GetAttribute("CanReplace") then
				return
			end

			local char = participant:GetCharacter()
			participant:TryDropItem(foundItem, if char then (interactable.Model:GetPivot().Position - char:GetPivot().Position).Unit else nil)
		end

		participant:AddItem(interactable.Extras.Item)
	end,
}

Item.Interactable = definition

return Item