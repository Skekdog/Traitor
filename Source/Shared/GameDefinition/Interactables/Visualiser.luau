local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local DamageSource = require(ReplicatedStorage.API.DamageSource)
local RoundHooks = require(ReplicatedStorage.API.RoundHooks)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local SPHERE_TWEEN_INFO = TweenInfo.new(
	0.25,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.In
)

local VISUALISE_INTERVAL = 15
local VISUALISE_DURATION = 5
local INITIAL_VISUALISE_DELAY = 3

local VISUALISE_MATERIAL = Enum.Material.ForceField
local VISUALISE_COLOUR = Color3.fromRGB(0, 110, 255)
local TRACER_TRANSPARENCY = 0.5

local VISUALISE_ITEM_COLOUR = Color3.fromRGB(255, 255, 255)
local VISUALISE_TRACE_COLOUR = Color3.fromRGB(200, 80, 80)

local VISUALISATION_RADIUS = 7.5

local activeVisualisers: {Visualiser} = {}

type Visualiser = Types.Prop & {
	Interactable: Types.InteractableDefinition,
	Extras: {
		Removed: boolean?,
		Player: Player?,
		LastVisualisedAt: number?,
		CurrentVisualisation: {Sphere: Part, Visualisations: {DeathData}}?,
		[any]: nil,
	}
}

type DeathData = {
	Visualisers: {Visualiser},
	Victim: Model,
	Killer: Model,
	Tracer: Part,
}

local deathData: {[Model]: DeathData} = {}

local function stopVisualisation(data: DeathData): ()
	data.Victim.Parent = nil
	data.Tracer.Parent = nil
	data.Killer.Parent = nil
	data.Visualisers = {}
end

local function stopVisualising(visualiser: Visualiser): ()
	local currentVisualisation = visualiser.Extras.CurrentVisualisation
	if not currentVisualisation then
		return
	end

	TweenService:Create(currentVisualisation.Sphere, SPHERE_TWEEN_INFO, {Size = Vector3.zero}):Play()
	task.delay(SPHERE_TWEEN_INFO.Time, currentVisualisation.Sphere.Destroy, currentVisualisation.Sphere)

	local toRemove: {DeathData} = {}
	local toRemoveOnlyFromCurrentVisualisation: {DeathData} = {}
	for _, data in currentVisualisation.Visualisations do
		if #data.Visualisers == 1 then
			stopVisualisation(data)
			table.insert(toRemoveOnlyFromCurrentVisualisation, data)
		else
			table.insert(toRemove, data)
		end
	end

	for _, data in toRemove do
		table.remove(currentVisualisation.Visualisations, table.find(currentVisualisation.Visualisations, data) or error("Visualisation not found"))
		table.remove(data.Visualisers, table.find(data.Visualisers, visualiser) or error("Visualiser not found"))
	end

	for _, data in toRemoveOnlyFromCurrentVisualisation do
		table.remove(currentVisualisation.Visualisations, table.find(currentVisualisation.Visualisations, data) or error("Visualisation not found"))
	end
end

local function visualise(corpses: {[Model]: DeathData}, visualiser: Visualiser): ()
	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.zero
	sphere.Position = GetPrimaryPart(visualiser.Model).Position
	sphere.Material = VISUALISE_MATERIAL
	sphere.Color = VISUALISE_COLOUR
	sphere.Anchored = false
	sphere.CanCollide = false
	sphere.Massless = true
	sphere.CanTouch = false
	sphere.CanQuery = false

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = GetPrimaryPart(visualiser.Model)
	weld.Part1 = sphere
	weld.Parent = visualiser.Model

	TweenService:Create(sphere, SPHERE_TWEEN_INFO, {Size = Vector3.new(VISUALISATION_RADIUS * 2, VISUALISATION_RADIUS * 2, VISUALISATION_RADIUS * 2)}):Play()

	PlaySound(5114177371, nil, visualiser.Model, {
		Volume = 0.5,
		RollOffMinDistance = 5,
		RollOffMaxDistance = 15,
		SoundGroup = SoundService.AllSounds :: SoundGroup,
	})

	sphere.Parent = workspace.Projectiles

	visualiser.Extras.CurrentVisualisation = {
		Sphere = sphere,
		Visualisations = {},
	}

	for _, data in corpses do
		table.insert(data.Visualisers, visualiser)
		table.insert(visualiser.Extras.CurrentVisualisation.Visualisations, data)
		data.Victim.Parent = workspace.Projectiles
		data.Tracer.Parent = workspace.Projectiles
		data.Killer.Parent = workspace.Projectiles
	end

	task.delay(VISUALISE_DURATION, function()
		if visualiser.Extras.Removed then
			return
		end

		stopVisualising(visualiser)
	end)
end

local function copyCharacter(char: Model): Model
	char.Archivable = true
	char = char:Clone()

	for _, v in char:GetDescendants() do
		if not v:IsA("BasePart") and not v:IsA("SpecialMesh") then
			v:Destroy()
			continue
		end

		if not v:IsA("BasePart") then
			continue
		end

		v.Anchored = true
		v.CanCollide = false
		v.CanTouch = false
		v.CanQuery = false
		v.CollisionGroup = "Default"
		v.Material = VISUALISE_MATERIAL
		v.Color = if v.Name == "Item" then VISUALISE_ITEM_COLOUR else VISUALISE_COLOUR
	end

	return char
end

RoundHooks.OnDeath["Visualiser"] = function(round: Types.Round, participant: Types.Participant, defer: boolean): ()
	local corpse = participant.Corpse
	if not corpse then
		return
	end

	if not DamageSource.IsFirearm(corpse.CorpseView.DamageSource) then
		return
	end

	local params = corpse.DamageParams

	local attacker = corpse.Killer
	if not attacker then
		return
	end

	local char = corpse.Model
	if not char then
		return
	end

	local attackerChar = attacker:GetCharacter()
	if not attackerChar then
		return
	end

	char = copyCharacter(char)
	attackerChar = copyCharacter(attackerChar)

	local victimPos = params.HitPosition or char:GetPivot().Position
	local attackerPos = params.Origin or attackerChar:GetPivot().Position

	local tracerVector = victimPos - attackerPos
	local tracer = Instance.new("Part")

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshId = "rbxassetid://9788624116"
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.Parent = tracer
	mesh.Scale = Vector3.new(0.1, 0.1, tracerVector.Magnitude / 2)

	tracer.Material = VISUALISE_MATERIAL
	tracer.Color = VISUALISE_TRACE_COLOUR
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanTouch = false
	tracer.CanQuery = false
	tracer.Transparency = TRACER_TRANSPARENCY
	tracer.CFrame = CFrame.lookAt((victimPos + attackerPos) / 2, victimPos)

	task.spawn(function()
		task.wait()
		local corpse = participant.Corpse
		if not corpse or not corpse.Model then
			return
		end

		deathData[corpse.Model] = {
			Visualisers = {},
			Victim = char,
			Killer = attackerChar,
			Tracer = tracer,
		}
	end)
end

local function BeforeTakeDamage(interactable: Types.Prop, params: Types.DamageParams?): boolean
	if not params then
		return false
	end

	local attacker = params.Attacker
	if not attacker then
		return false
	end

	return attacker:GetRole().Definition.IsEvil or false
end

local function OnInteractServer(interactable: Types.Prop, participant: Types.Participant): ()
	local visualiser = interactable :: Visualiser

	if participant.Player ~= visualiser.Extras.Player :: Player? then
		return
	end

	local visualiserItem = participant.Round:GetItemDefinition(visualiser.Interactable.Name)
	if not visualiserItem then
		return warn("Could not find Decoy item")
	end

	if participant:GetItemOccupyingGroup(visualiserItem.ItemGroup) then
		return
	end

	visualiser.Model:Destroy()
	participant:AddItem(participant.Round:LoadItem(visualiserItem))
end

local function removeVisualiser(interactable: Types.Prop): ()
	local visualiser = interactable :: Visualiser

	visualiser.Extras.Removed = true
	table.remove(activeVisualisers, table.find(activeVisualisers, visualiser) or error("Visualiser not found"))
	stopVisualising(visualiser)
end

local function OnLoadServer(interactable: Types.Prop): ()
	local visualiser = interactable :: Visualiser

	visualiser.Extras.LastVisualisedAt = tick() - (VISUALISE_INTERVAL - INITIAL_VISUALISE_DELAY)

	visualiser.Model.Destroying:Connect(function()
		removeVisualiser(visualiser)
	end)

	table.insert(activeVisualisers, visualiser)
end

local function forEachVisualiser(visualiser: Visualiser): ()
	if (visualiser.Extras.LastVisualisedAt or 0) + VISUALISE_INTERVAL > tick() then
		return
	end

	assert(visualiser.Model:IsA("BasePart"))

	visualiser.Extras.LastVisualisedAt = tick()

	local corpsesInRange: {[Model]: DeathData} = {}

	for _, part in workspace:GetPartBoundsInRadius(visualiser.Model.Position, VISUALISATION_RADIUS) do
		local model = part:FindFirstAncestorOfClass("Model")
		if not model or corpsesInRange[model] then
			continue
		end

		local visualisation = deathData[model]
		if not visualisation or (visualisation.Victim:GetPivot().Position - visualiser.Model.Position).Magnitude > VISUALISATION_RADIUS then
			continue
		end

		corpsesInRange[model] = visualisation
	end

	visualise(corpsesInRange, visualiser)
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