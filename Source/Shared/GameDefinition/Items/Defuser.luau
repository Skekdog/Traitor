local ReplicatedStorage = game:GetService("ReplicatedStorage")
local C4 = require(ReplicatedStorage.Shared.GameDefinition.Interactables.C4)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local params = RaycastParams.new()
params.CollisionGroup = "WeaponHitTargets"
params.FilterDescendantsInstances = {workspace.Characters}
params.FilterType = Enum.RaycastFilterType.Exclude

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",
	Name = "Defuser",
	Description = "Can be used to safely defuse any C4s.",
	Icon = "rbxassetid://96183272088937",

	Slot = 8,
	CanDrop = true,

	Model = ReplicatedStorage.Assets.WeaponModels.Defuser,

	CreditCost = 1,
	MaxStock = 2,

	PrimaryHint = "Defuse C4",
	PrimaryToggled = true,
	PrimaryFireServer = function(_, _, origin: Vector3, direction: Vector3, participant: Types.Participant): ()
		local result = workspace:Raycast(origin, direction * 7.5, params)
		if not result then
			return
		end

		local interactable = participant.Round:GetInteractable(result.Instance :: BasePart)
		if not interactable then
			return
		end

		if interactable.Definition == C4.Interactable then
			C4.TryDisarm(interactable :: C4.C4, participant, 1, true)
		end
	end
}

return item