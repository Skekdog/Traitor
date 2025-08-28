local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandardDoor = require(ReplicatedStorage.Shared.Actions.StandardDoor)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

local definition: Types.InteractableDefinition = {
	Name = "Door",
	InteractionRange = 7.5,
	IsContinuousInteraction = false,
	Model = Instance.new("Part"),

	OnInteractClient = function(interactable: Types.Interactable): ()
		local request: StandardDoor.ClientInteraction = {
			Kind = "ClientInteraction" :: "ClientInteraction",
			Door = interactable.Model,
		}
		StandardDoor(request)
	end,
}

module.Interactable = definition

return module