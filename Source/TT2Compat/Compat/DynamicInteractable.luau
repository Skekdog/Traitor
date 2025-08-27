local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Interactable = require(ReplicatedStorage.Shared.RoundRule.Interactable)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

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

local function getUseText(mapThing: Types.MapThing): string?
	local useText = mapThing:GetAttribute("UseText")
	if typeof(useText) ~= "string" then
		useText = nil
	end
	return useText :: string?
end

local function createNewInteractable(mapThing: Types.MapThing): Types.Interactable
	local useText = getUseText(mapThing)

	local definition: Types.InteractableDefinition = {
		InteractionRange = 7.5,
		Model = mapThing,

		IsContinuousInteraction = false,
		Name = mapThing.Name,

		OnInteractClient = OnInteract,
		OnInteractServer = OnInteract,

		OnBreakServer = OnBreak,

		DefaultHintText = useText,
	}

	local interactable = Interactable.new(definition, mapThing)

	mapThing:GetAttributeChangedSignal("UseText"):Connect(function()
		interactable.HintTextClient = getUseText(mapThing)
	end)

	return interactable
end

if RunService:IsClient() then
	local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
	local GetInteractableDefinition = require(ReplicatedStorage.Shared.LocalState.GetInteractableDefinition)

	local function onDescendantAdded(descendant: Instance): ()
		if descendant:GetAttribute("Button") and (descendant:IsA("BasePart") or descendant:IsA("Model")) then
			local gamemode, map = LocalRoundInfo.Gamemode(), LocalRoundInfo.Map()
			if not gamemode or not map or GetInteractableDefinition(descendant.Name, gamemode, map) then
				return
			end
			local interactable = createNewInteractable(descendant)
			LocalRoundInfo.Interactables()[descendant] = interactable
			LocalRoundInfo.Interactables:Invoke()

			descendant:GetAttributeChangedSignal("Button"):Connect(function()
				local value = descendant:GetAttribute("Button")
				if value then
					descendant:AddTag("Prop")
					descendant:AddTag("Interactable")
					LocalRoundInfo.Interactables()[descendant] = interactable
					LocalRoundInfo.Interactables:Invoke()
				else
					descendant:RemoveTag("Prop")
					descendant:RemoveTag("Interactable")
					LocalRoundInfo.Interactables()[descendant] = nil
					LocalRoundInfo.Interactables:Invoke()
				end
			end)
		end
	end

	LocalRoundInfo.Map:Connect(function(map)
		if not map then
			return
		end

		if not map.Definition.Extras or not map.Definition.Extras.CompatibilityMode then
			return
		end

		for _, v in map.Dynamic:GetDescendants() do
			onDescendantAdded(v)
		end

		map.Dynamic.DescendantAdded:Connect(onDescendantAdded)
	end, true)
	return module
end

local RoundHandler = require(ServerScriptService.RoundHandler)
function module.TryCreateNewInteractable(mapThing: Types.MapThing): Types.Interactable?
	local round = RoundHandler.Round()

	if not mapThing:GetAttribute("Button") or not mapThing:IsDescendantOf(round:GetMap().Dynamic) then
		return nil
	end

	return createNewInteractable(mapThing)
end

return module