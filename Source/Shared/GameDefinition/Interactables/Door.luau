local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandardDoor = require(ReplicatedStorage.Shared.Actions.StandardDoor)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

local function setLockedHint(interactable: Types.Interactable): ()
	local locked = interactable.Model:GetAttribute("Locked")
	interactable.HintTextClient = if locked then "This door is locked" else nil
end

local definition: Types.InteractableDefinition = {
	Name = "Door",
	InteractionRange = 7.5,
	IsContinuousInteraction = false,

	OnLoadClient = function(interactable: Types.Interactable): ()
		setLockedHint(interactable)
		interactable.Model:GetAttributeChangedSignal("Locked"):Connect(function()
			setLockedHint(interactable)
		end)
	end,

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