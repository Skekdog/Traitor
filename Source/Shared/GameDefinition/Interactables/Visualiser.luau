local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Participant = require(ReplicatedStorage.Shared.RoundRule.Participant)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local VISUALISE_INTERVAL = 15
local VISUALISE_DURATION = 5

local VISUALISE_MATERIAL = Enum.Material.ForceField
local VISUALISE_COLOUR = Color3.fromRGB(0, 110, 255)

local VISUALISATION_RADIUS = 7.5

local MAX_CORPSE_MOVED_DISTANCE = 10

local activeVisualisers: {Visualiser} = {}

type Visualiser = Types.Interactable & {
	Extras: {
		Player: Player?,
		LastVisualisedAt: number?,
		[any]: nil,
	}
}

local visualisations: {[Model]: {
	OriginalCorpsePosition: Vector3,
	Victim: Model,
	Killer: Model,
}} = {}

local originalOnDeath = Participant.OnDeath
local function patchedOnDeath(participant: Types.Participant, params: Types.DamageParams, deferVictoryCheck: boolean): ()
	-- if params.Source ~= "Shot" and (typeof(params.Source) ~= "table" or params.Source.Kind ~= "Gun") then
	-- 	return
	-- end

	-- local attacker = params.Attacker
	-- if not attacker then
	-- 	return
	-- end

	local char = participant:GetCharacter()
	if not char then
		return
	end

	char.Archivable = true
	char = char:Clone()

	local originalPosition = char:GetPivot().Position
	for _, v in char:GetDescendants() do
		if not v:IsA("BasePart") and not v:IsA("SpecialMesh") then
			v:Destroy()
			continue
		end

		if not v:IsA("BasePart") then
			continue
		end

		v.Anchored = true
		v.Material = VISUALISE_MATERIAL
		v.Color = VISUALISE_COLOUR
	end

	task.defer(function()
		local corpse = participant:GetCharacter()
		if not corpse then
			return
		end

		visualisations[corpse] = {
			OriginalCorpsePosition = originalPosition,
			Victim = char,
			Killer = char,
		}
	end)
end

Participant.OnDeath = function(participant: Types.Participant, params: Types.DamageParams, deferVictoryCheck: boolean): ()
	patchedOnDeath(participant, params, deferVictoryCheck)
	originalOnDeath(participant, params, deferVictoryCheck)
end

local function BeforeTakeDamage(interactable: Visualiser, params: Types.DamageParams?): boolean
	if not params then
		return false
	end

	local attacker = params.Attacker
	if not attacker then
		return false
	end

	local role = attacker:GetRole()
	return if role then role.Definition.IsBadGuys or false else false
end

local function OnInteractServer(interactable: Visualiser, participant: Types.Participant): ()
	if participant.Player ~= interactable.Extras.Player :: Player? then
		return
	end

	local visualiserItem = participant.Round:GetItemDefinition(interactable.Definition.Name)
	if not visualiserItem then
		return warn("Could not find Decoy item")
	end

	if visualiserItem.Slot and participant:IsItemSlotOccupied(visualiserItem.Slot) then
		return
	end

	interactable.Object:Destroy()
	participant:GiveItemFromItemDefinition(visualiserItem)
end

local function OnLoadServer(interactable: Visualiser): ()
	interactable.Extras.LastVisualisedAt = 0

	interactable.Object.Destroying:Connect(function()
		table.remove(activeVisualisers, table.find(activeVisualisers, interactable) or error("Could not find"))
	end)

	table.insert(activeVisualisers, interactable)
end

local function forEachVisualiser(visualiser: Visualiser): ()
	if (visualiser.Extras.LastVisualisedAt or 0) + VISUALISE_INTERVAL > tick() then
		return
	end

	visualiser.Extras.LastVisualisedAt = tick()

	local corpsesInRange: {Model} = {}

	for _, part in workspace:GetPartBoundsInRadius(visualiser.Object.Position, VISUALISATION_RADIUS) do
		local model = part:FindFirstAncestorOfClass("Model")
		if not model or table.find(corpsesInRange, model) then
			continue
		end

		local visualisation = visualisations[model]
		if not visualisation or (visualisation.OriginalCorpsePosition - model:GetPivot().Position).Magnitude > MAX_CORPSE_MOVED_DISTANCE then
			continue
		end
		
		table.insert(corpsesInRange, model)
	end

	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.new(VISUALISATION_RADIUS * 2, VISUALISATION_RADIUS * 2, VISUALISATION_RADIUS * 2)
	sphere.Position = visualiser.Object.Position
	sphere.Material = VISUALISE_MATERIAL
	sphere.Color = VISUALISE_COLOUR
	sphere.Anchored = true
	sphere.CanCollide = false

	sphere.Parent = workspace.Projectiles

	for _, corpse in corpsesInRange do
		local visualisation = visualisations[corpse]
		local victim = visualisation.Victim
		victim.Parent = workspace.Projectiles
	end

	task.delay(VISUALISE_DURATION, function()
		for _, corpse in corpsesInRange do
			local visualisation = visualisations[corpse]
			local victim = visualisation.Victim
			victim.Parent = nil
		end

		sphere:Destroy()
	end)
end

RunService.Heartbeat:Connect(function()
	for _, visualiser in activeVisualisers do
		forEachVisualiser(visualiser)
	end
end)

local interactable: Types.InteractableDefinition = {
	Name = "Visualiser",
	
	Model = ReplicatedStorage.Assets.InteractableModels.Visualiser,

	InteractionRange = 7.5,
	IsContinuousInteraction = false,

	BeforeTakeDamage = BeforeTakeDamage,

	OnLoadServer = OnLoadServer,
	OnInteractServer = OnInteractServer,
}

return interactable