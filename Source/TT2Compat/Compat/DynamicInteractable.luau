local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local GetInteractableDefinition = require(ReplicatedStorage.Shared.LocalState.GetInteractableDefinition)
local Interactable = require(ReplicatedStorage.Shared.RoundRule.Interactable)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function OnInteract(interactable: Types.Interactable, participant: Types.Participant?): ()
	local name = if participant then "ButtonServer" else "ButtonClient"
	local Button = interactable.Model:FindFirstChild(name)
	if not Button or not Button:IsA("ModuleScript") then
		return
	end
	(require)(Button).Began(if participant then participant.Player else nil)
end

local function OnBreak(interactable: Types.Interactable, params: Types.DamageParams): ()
	local Break = interactable.Model:FindFirstChild("OnBreak")
	if not Break or not Break:IsA("ModuleScript") then
		return
	end
	(require)(Break)(interactable, params)
end

local function createNewInteractable(mapThing: Types.MapThing): Types.Interactable
	local definition: Types.InteractableDefinition = {
		InteractionRange = 7.5,
		Model = mapThing,

		IsContinuousInteraction = false,
		Name = mapThing.Name,

		OnInteractClient = OnInteract,
		OnInteractServer = OnInteract,

		OnBreakServer = OnBreak,
	}
	local interactable = Interactable.new(definition, mapThing)
	return interactable
end

local function tryCreateNewInteractable(mapThing: Types.MapThing): Types.Interactable?
	local RoundHandler = require(ServerScriptService.RoundHandler)
	local round = RoundHandler.Round()

	if not mapThing:HasTag("Interactable") or not mapThing:IsDescendantOf(round:GetMap().Dynamic) then
		return nil
	end

	return createNewInteractable(mapThing)
end

if RunService:IsClient() then
	local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
	local GetTaggedDescendants = require(ReplicatedStorage.Shared.RoundRule.Common.GetTaggedDescendants)

	local function onDescendantAdded(descendant: Instance): ()
		if descendant:HasTag("Interactable") and (descendant:IsA("BasePart") or descendant:IsA("Model")) then
			local gamemode, map = LocalRoundInfo.Gamemode(), LocalRoundInfo.Map()
			if not gamemode or not map or GetInteractableDefinition(descendant.Name, gamemode, map) then
				return
			end
			local interactable = createNewInteractable(descendant)
			LocalRoundInfo.Interactables()[descendant] = interactable
			LocalRoundInfo.Interactables:Invoke()
		end
	end

	LocalRoundInfo.Map:Connect(function(map)
		if not map then
			return
		end

		if not map.Definition.Extras or not map.Definition.Extras.CompatibilityMode then
			return
		end

		for _, v in GetTaggedDescendants(map.Dynamic, "Interactable") do
			onDescendantAdded(v)
		end

		map.Dynamic.DescendantAdded:Connect(onDescendantAdded)
	end, true)
	return nil
end

local Round = require(ReplicatedStorage.Shared.RoundRule.Round)
local originalGetInteractable = Round.GetInteractable
Round.GetInteractable = function(round: Types.Round, model: Types.MapThing): Types.Interactable?
	return originalGetInteractable(round, model) or tryCreateNewInteractable(model)
end

return nil