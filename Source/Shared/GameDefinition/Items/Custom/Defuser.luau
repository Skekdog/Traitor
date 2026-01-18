local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local C4 = require(ReplicatedStorage.Shared.GameDefinition.Interactables.C4)

local params = RaycastParams.new()
params.CollisionGroup = "WeaponHitTargets"
params.FilterDescendantsInstances = {workspace.Characters}
params.FilterType = Enum.RaycastFilterType.Exclude

local item = Custom({
	Name = "Defuser",
	Description = "Can be used to safely defuse any C4s.",
	IconContent = Content.fromAssetId(96183272088937),

	ItemGroup = ItemGroups.RoleUtility,

	Model = ReplicatedStorage.Assets.ItemModels.Defuser,

	Cost = 1,
	MaxStock = 2,

	PrimaryHint = "Defuse C4",
	PrimaryToggled = true,
	PrimaryFireServer = function(_, participant, origin: Vector3, direction: Vector3): ()
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
})

return item