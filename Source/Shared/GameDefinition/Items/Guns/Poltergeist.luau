local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Impulse = require(ReplicatedStorage.API.Impulse)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local BehaviourTypes = require(ReplicatedStorage.API.Item.Behaviour.BehaviourTypes)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local GetMapObjectWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapObjectWithTag)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local MAX_RANGE = 10000

local function isPartValid(part: BasePart): boolean
	local prop = GetMapObjectWithTag(part, "Prop")
	return if prop then Impulse.CanImpulse(part) and not prop:HasTag("Interactable") else false
end

local function clientThing(origin: Vector3, direction: Vector3): BehaviourTypes.HitscanResult?
	local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
	local Raycasts = require(ReplicatedStorage.API.Item.Behaviour.Raycasts)

	local map = workspace:FindFirstChild("Map")
	if not map then
		return nil
	end

	local result = Raycasts.Hitscan(Raycasts.GetDefaultRaycastParams(assert(LocalCharacter.Character())), origin, direction, MAX_RANGE)
	if not result.Hit or not isPartValid(result.Hit.Part) then
		return nil
	end

	return result
end

local function preRenderClient(item: Types.Item, dt: number): ()
	local Raycasts = require(ReplicatedStorage.API.Item.Behaviour.Raycasts)

	if clientThing(Raycasts.GetOrigin(), Raycasts.GetDirection()) then
		item.LaserColor = Color3.new(0, 1, 0)
	else
		item.LaserColor = Color3.new(1, 0, 0)
	end
end

local function beforeHitAnything(_, params: Types.DamageParams, round: Types.Round): boolean
	local hitPart = assert(params.HitPart)
	return isPartValid(hitPart)
end

type PoltInfo = {
	LastTime: number,
	PoltPhase: number,
	Attacker: Types.Participant,
}

local poltedProps: {[Types.Prop]: PoltInfo} = {}

local function beforeHitProp(_,params: Types.DamageParams, hitProp: Types.Prop): boolean
	assert(params.Attacker)

	if hitProp.Kind ~= "Prop" then
		return false
	end

	if not isPartValid(GetPrimaryPart(hitProp.Model)) then
		return false
	end

	local info = poltedProps[hitProp]
	if info then
		return false
	end

	info = {
		LastTime = 0,
		PoltPhase = 1,
		Attacker = params.Attacker,
	}

	poltedProps[hitProp] = info

	return true
end

local phaseAdvanceTimes = {
	[1] = 1,
	[2] = 1.5,
	[3] = 1.5,
	[4] = 0.8,
	[5] = 0.8,
	[6] = 0.8,
}

local function doPropPolt(prop: Types.Prop, info: PoltInfo): ()
	assert(prop.Round)

	if not prop.Model:IsDescendantOf(workspace) then
		poltedProps[prop] = nil
		return
	end

	local now = tick()
	if now - info.LastTime < phaseAdvanceTimes[info.PoltPhase] then
		return
	end

	info.LastTime = now
	info.PoltPhase += 1

	if info.PoltPhase > #phaseAdvanceTimes then
		poltedProps[prop] = nil
		return
	end

	local nearestParticipant: Types.Participant?
	local nearestDistance = math.huge

	local propRoot = GetPrimaryPart(prop.Model)

	for _, participant in prop.Round:GetParticipants() do
		assert(participant)
		local distance = participant.Player:DistanceFromCharacter(propRoot.Position)
		if distance ~= 0 and distance < nearestDistance then
			nearestDistance = distance
			nearestParticipant = participant
		end
	end

	if not nearestParticipant then
		return
	end

	local character = nearestParticipant:GetCharacter()
	if not character then
		return
	end

	local root = character.PrimaryPart
	if not root then
		return
	end

	local direction = (propRoot.Position - root.Position).Unit
	Impulse.ApplyImpulse(propRoot, -direction * 50, true, nil, info.Attacker)

	if info.PoltPhase == #phaseAdvanceTimes then
		local params = {
			Damage = 10,
			FalloffStart = 0,
			FalloffEnd = 15,
			Pressure = 50000,
			VisualRadius = 15,
			Position = propRoot.Position,
			Attacker = info.Attacker,

			BeforeHitParticipant = function(_, _, hitParticipant: Types.Participant): boolean
				return hitParticipant ~= info.Attacker
			end,
		}
		local Combat = require(ReplicatedStorage.API.Combat)
		Combat.MakeExplosion(params)
		return
	end

	PlaySound(7129285090, nil, GetPrimaryPart(prop.Model), {
		Volume = 0.5,
		RollOffMinDistance = 10,
		RollOffMaxDistance = 25,
	})
end

local function heartbeat()
	for prop, info in poltedProps do
		doPropPolt(prop, info)
	end
end

if RunService:IsServer() then
	RunService.Heartbeat:Connect(heartbeat)
end

local Poltergeist = Gun({
	Name = "Poltergeist",
	Description = "Attaches thrusters to props, blasting them towards others.",
	IconContent = Content.fromAssetId(103677163409705),

	IsEvilItem = true,

	IsAimable = false,

	Model = ReplicatedStorage.Assets.ItemModels.Poltergeist,

	LaserColor = Color3.new(),

	HoldAnimation = Content.fromAssetId(10247380824),

	ItemGroup = ItemGroups.RoleUtility,
	MaxStock = 2,
	Cost = 1,

	PrimaryInterval = 3,
	AmmoDefinition = Ammo["Poltergeist"],

	PreRenderClient = preRenderClient,

	PrimaryFireClient = function(item, origin, direction)
		local Client = require(ReplicatedStorage.API.Item.Behaviour.Client)
		local request = clientThing(origin, direction)
		if not request then
			item:ResetLastUse("Primary")
			return false
		end

		return Client.PrimaryFire(item, origin, direction)
	end,

	PrimaryFireServer =
		if RunService:IsServer() then
			require(ReplicatedStorage.API.Item.Behaviour.Server).PrimaryFire
		else
			function() return nil
		end,

	BeforeHitAnything = beforeHitAnything,
	BeforeHitProp = beforeHitProp,
})

return table.freeze(Poltergeist)