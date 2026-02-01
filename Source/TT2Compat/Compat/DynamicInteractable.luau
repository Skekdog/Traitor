local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local Prop = require(ReplicatedStorage.Shared.RoundRule.Prop)

local module = {}

local function OnInteract(prop: Types.Prop, participant: Types.Participant?): ()
	local name = if participant then "ButtonServer" else "ButtonClient"
	local Button = prop.Model:FindFirstChild(name)
	if not Button or not Button:IsA("ModuleScript") then
		return
	end
	(require)(Button).Began(if participant then participant.Player else nil)
end

local function OnBreak(prop: Types.Prop, params: Types.DamageParams): ()
	local Break = prop.Model:FindFirstChild("OnBreak")
	if not Break or not Break:IsA("ModuleScript") then
		return
	end
	(require)(Break)(prop, params)
end

local function getUseText(MapObject: Types.MapObject): string?
	local useText = MapObject:GetAttribute("UseText")
	if typeof(useText) ~= "string" then
		useText = nil
	end
	return useText :: string?
end

local function createNewInteractable(MapObject: Types.MapObject): Types.Prop
	local useText = getUseText(MapObject)

	local definition: Types.InteractableDefinition = {
		InteractionRange = 7.5,
		Model = MapObject,

		IsContinuousInteraction = false,
		Name = MapObject.Name,
		DisplayName = MapObject:GetAttribute("DisplayName") :: string?,
		HideName = MapObject:GetAttribute("ShowName") ~= true and not MapObject:GetAttribute("DisplayName"),

		OnInteractClient = OnInteract,
		OnInteractServer = OnInteract,

		OnBreakServer = OnBreak,

		DefaultHintText = useText,
	}


	MapObject:AddTag("Prop")
	MapObject:AddTag("Interactable")
	local interactable = Prop.new(MapObject, nil, definition)

	MapObject:GetAttributeChangedSignal("UseText"):Connect(function()
		interactable.HintTextClient = getUseText(MapObject)
	end)

	return interactable
end

if RunService:IsClient() then
	local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
	local GetInteractableDefinition = require(ReplicatedStorage.Shared.LocalState.GetInteractableDefinition)

	local function onDescendantAdded(descendant: Instance): ()
		if (not descendant:IsA("Model") and not descendant:IsA("BasePart")) or descendant:HasTag("Interactable") then
			return
		end
		local gamemode, map = LocalRoundInfo.Gamemode(), LocalRoundInfo.Map()
		if not gamemode or not map or GetInteractableDefinition(descendant.Name, gamemode, map) then
			return
		end

		local interactable: Types.Prop?
		if descendant:GetAttribute("Button") then
			interactable = createNewInteractable(descendant)
			LocalRoundInfo.Interactables()[descendant] = interactable
			LocalRoundInfo.Interactables:Invoke()
		end

		descendant:GetAttributeChangedSignal("Button"):Connect(function()
			local value = descendant:GetAttribute("Button")
			if value then
				descendant:AddTag("Prop")
				descendant:AddTag("Interactable")
				LocalRoundInfo.Interactables()[descendant] = interactable or createNewInteractable(descendant)
				LocalRoundInfo.Interactables:Invoke()
			else
				descendant:RemoveTag("Prop")
				descendant:RemoveTag("Interactable")
				LocalRoundInfo.Interactables()[descendant] = nil
				LocalRoundInfo.Interactables:Invoke()
			end
		end)
	end

	LocalRoundInfo.Map:Connect(function(map)
		if not map then
			return
		end

		for _, v in map.Structure.Dynamic:GetDescendants() do
			onDescendantAdded(v)
		end

		map.Structure.Dynamic.DescendantAdded:Connect(onDescendantAdded)
	end, true)
	return module
end

local RoundHandler = require(ServerScriptService.RoundHandler)
function module.TryCreateNewInteractable(MapObject: Types.MapObject): Types.Prop?
	local round = RoundHandler.Round()

	if not MapObject:GetAttribute("Button") or not MapObject:IsDescendantOf(round:GetMap().Structure.Dynamic) then
		return nil
	end

	return createNewInteractable(MapObject)
end

return module