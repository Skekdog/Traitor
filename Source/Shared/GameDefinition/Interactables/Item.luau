local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local Item = {}

type ItemInteractable = Types.Interactable & {
	Extras: {
		Item: Types.AnyItem,
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
			if foundItem.Definition.PreventUnequip or not foundItem.Definition.CanDrop then
				return
			end

			local char = participant:GetCharacter()
			participant:DropItem(foundItem, if char then (interactable.Extras.Item.Model:GetPivot().Position - char:GetPivot().Position).Unit else nil)
		end

		participant:AddItem(interactable.Extras.Item)
	end,
}

Item.Interactable = definition

return Item