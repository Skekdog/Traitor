local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DNATraces = require(ReplicatedStorage.API.DNATraces)
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
		DNATraces.Add(interactable, participant, nil, Content.fromAssetId(93284379186217), interactable.Model)
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

local function OnBreakServer(prop: Types.Prop, params: Types.DamageParams): ()
	Server.CreateExplosion(prop.Round or error("Missing round"), ExplosionParams.new({
		Damage = 150,
		FalloffStart = 15,
		FalloffEnd = 25,
		Pressure = 50000,
		VisualRadius = 25,
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