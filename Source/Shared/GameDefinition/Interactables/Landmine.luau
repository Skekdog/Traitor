local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DNATraces = require(ReplicatedStorage.API.DNATraces)
local KillHighlights = require(ReplicatedStorage.API.Item.Behaviour.KillHighlights)
local Server = require(ReplicatedStorage.API.Item.Behaviour.Server)
local Types = require(ReplicatedStorage.API.Types)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)

type LandmineServer = Types.Prop & {
	Interactable: Types.InteractableDefinition,
	Extras: {
		Participant: Types.Participant?,
	}
}

local function OnLoadServer(interactable: Types.Prop): ()
	local landmine = interactable :: LandmineServer

	local participant: Types.Participant? = landmine.Extras.Participant
	if participant then
		DNATraces.Add(interactable, participant, nil, Content.fromAssetId(82684167883573), interactable.Model)
	end
end

local function OnInteractServer(interactable: Types.Prop, participant: Types.Participant): ()
	local landmine = interactable :: LandmineServer

	if participant ~= landmine.Extras.Participant then
		return
	end

	local landmineItem = participant.Round:GetItemDefinition(landmine.Interactable.Name)
	if not landmineItem then
		return warn("Could not find Landmine item")
	end

	if participant:GetItemOccupyingGroup(landmineItem.ItemGroup) then
		return
	end

	interactable.Model:Destroy()
	participant:AddItem(participant.Round:LoadItem(landmineItem))
end

local highlights: {KillHighlights.ItemKillHighlight} = {
	{
		Title = "It's a Trap!",
		Description = "%s laid a trap, but they were not to blame for 1 death.",
		Priority = 2,
		Threshold = 1,
	},
	{
		Title = "It's a Trap!",
		Description = "%s laid a trap, but they were not to blame for %d deaths.",
		Priority = 3,
		Threshold = 2,
	},
}

local function OnBreakServer(prop: Types.Prop, params: Types.DamageParams): ()
	local killHighlights = KillHighlights(table.unpack(highlights))
	Server.CreateExplosion(prop.Round or error("Missing round"), ExplosionParams.new({
		Damage = 150,
		FalloffStart = 15,
		FalloffEnd = 25,
		Pressure = 50000,
		VisualRadius = 25,
		BeforeHitParticipant = function(_, params, participant)
			return killHighlights({Name = "Landmine"}, params, participant)
		end,
	}, GetPrimaryPart(prop.Model).Position, params.Attacker))
end

local model = ReplicatedStorage.Assets.ItemModels.Landmine

local interactable: Types.InteractableDefinition = {
	Name = "Landmine",

	Model = model,

	InteractionRange = 7.5,
	IsContinuousInteraction = false,

	OnInteractServer = OnInteractServer,
	OnLoadServer = OnLoadServer,

	OnBreakServer = OnBreakServer,
}

return table.freeze(interactable)