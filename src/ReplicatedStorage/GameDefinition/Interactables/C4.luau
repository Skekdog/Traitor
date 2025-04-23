local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.RoundRule.Types)

local interactable: Types.InteractableDefinition = {
	Name = "C4",

	Model = Instance.new("Part"),

	IsContinuousInteraction = false,
	InteractionRange = 7.5,

	OnInteractClient = function(object: Types.Interactable): ()
		print("Client C4 interaction:", object.Object.Name)
	end,

	OnInteractServer = function(object: Types.Interactable, participant: Types.Participant): ()
		print("Server C4 interaction:", object.Object.Name, participant.Player.Name)
	end,
}

return interactable