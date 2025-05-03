local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Participant = require(ReplicatedStorage.RoundRule.Participant)
local Types = require(ReplicatedStorage.RoundRule.Types)

local module = {}

local MAX_KILL_DISTANCE = 60
local MAX_KILL_TRACE_DURATION = 120

local MAX_SCAN_RANGE = 7.5

local remote: RemoteEvent
if RunService:IsServer() then
	remote = Instance.new("RemoteEvent")
	remote.Name = "DNARemote"
	remote.Parent = script
else
	local found = script:WaitForChild("DNARemote")
	assert(found:IsA("RemoteEvent"), "DNARemote must be a RemoteEvent")
	remote = found
end

function module.AddDNATrace(object: IHasDNATraces, target: Types.Participant, duration: number?): ()
	local traces = object.Extras.DNATraces or {}
	table.insert(traces, {
		ExpiresAt = if duration then workspace:GetServerTimeNow() + duration else nil,
		Target = target.Player.Name,
	})
	object.Extras.DNATraces = traces
end

export type IHasDNATraces = {
	Extras: {
		DNATraces: {DNATrace}?,
	},
}

type DNATrace = {
	ExpiresAt: number,
	Target: string,
}

type Participant = Types.Participant & IHasDNATraces

local originalOnDeath = Participant.OnDeath
local function patchedOnDeath(participant: Participant, params: Types.DamageParams, deferVictoryCheck: boolean): ()
	local attacker = params.Attacker
	if not attacker then
		return
	end

	if attacker:HasSelfDefenseAgainstParticipant(participant) then
		return
	end

	local char = participant:GetCharacter()
	if not char then
		return
	end

	local source: Types.DamageSource = params.Source
	local isEligible = true-- source == "Shot" or source == "Bludgeon" or source == "Stab" or if typeof(source) == "table" then source.Kind == "Gun" or source.Kind == "Melee" else false
	if not isEligible then
		return
	end

	local distance = attacker.Player:DistanceFromCharacter(char:GetPivot().Position)
	if distance == 0 then
		return
	end

	local duration = math.lerp(MAX_KILL_TRACE_DURATION, 0, distance / MAX_KILL_DISTANCE)
	module.AddDNATrace(participant, attacker, duration)

	participant:AddCorpseIcon({
		Name = "DNATrace",
		Icon = "rbxassetid://135886260297010",
		Description = "Traces of the killer's DNA are on the body. Use a DNA Scanner to track them.",
		DisplayText = `[TIMEUNTIL-{tostring(workspace:GetServerTimeNow() + duration)}]`,
	})
end

Participant.OnDeath = function(participant: Types.Participant, params: Types.DamageParams, deferVictoryCheck: boolean): ()
	patchedOnDeath(participant, params, deferVictoryCheck)
	originalOnDeath(participant, params, deferVictoryCheck)
end

local raycastParams = RaycastParams.new()
raycastParams.CollisionGroup = "WeaponHitTargets"
raycastParams.FilterDescendantsInstances = {workspace.Characters}
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
local function PrimaryFireServer(item: Types.Item, _, origin: Vector3, direction: Vector3, participant: Types.Participant): ()
	local result = workspace:Raycast(origin, direction * MAX_SCAN_RANGE * 1.1)
	if not result then
		return
	end

	local round = participant.Round
	local map = participant.Round:GetMap()

	local object: IHasDNATraces?

	local hitPart = result.Instance :: BasePart

	if hitPart:IsDescendantOf(workspace.Corpses) then
		local model = hitPart:FindFirstAncestorOfClass("Model")
		if model then
			object = round:GetParticipant(model.Name)
		end
	elseif hitPart:IsDescendantOf(map.Interactables) then
		local interactable = round:GetInteractable(hitPart)
		if interactable then
			object = interactable
		end
	elseif hitPart:IsDescendantOf(map.ItemSpawns) then
		local mapItem = round:GetItem(hitPart)
		if mapItem then
			object = mapItem
		end
	end

	if not object then
		return
	end

	remote:FireClient(participant.Player, object.Extras.DNATraces)
end

if RunService:IsClient() then
	remote.OnClientEvent:Connect(print)
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",
	Name = "DNAScanner",
	DisplayName = "DNA Scanner",

	Slot = 9,
	CanDrop = true,

	Model = ReplicatedStorage.WeaponModels.DNAScanner,
	HoldAnimation = "rbxassetid://10247423634",

	PrimaryToggled = true,
	PrimaryHint = "Scan Identified Body",
	PrimaryFireServer = PrimaryFireServer,
}

return item