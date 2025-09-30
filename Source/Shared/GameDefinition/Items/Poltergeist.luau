
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")

local LocalCharacter
local GetCentreRay
local Combat
if RunService:IsClient() then
	LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
	GetCentreRay = require(ReplicatedStorage.Shared.Camera.GetCentreRay)
else
	Combat = require(ServerScriptService.Combat.Combat)
end

local Impulse = require(ReplicatedStorage.API.Impulse)
local GetMapObjectWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapObjectWithTag)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)
local Ammo = require(script.Parent.Ammo)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local MAX_RANGE = 10000

local function raycast(char: Model, range: number): RaycastResult?
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	return workspace:Raycast(workspace.CurrentCamera.CFrame.Position, GetCentreRay().Direction.Unit * range, params)
end

local function isPartValid(part: BasePart): boolean
	local prop = GetMapObjectWithTag(part, "Prop")
	return if prop then Impulse.CanImpulse(part) and not prop:HasTag("Interactable") else false
end

local function clientThing(): boolean
	local map = workspace:FindFirstChild("Map")
	if not map then
		return false
	end

	local result = raycast(assert(LocalCharacter.Character()), MAX_RANGE)
	if not result then
		return false
	end

	return isPartValid(result.Instance)
end

local function preRenderClient(item: Types.AnyItem, dt: number): ()
	assert(item.Kind == "Gun")
	if clientThing() then
		item.Definition.LaserColor = Color3.new(0, 1, 0)
	else
		item.Definition.LaserColor = Color3.new(1, 0, 0)
	end
end

local function beforePrimaryFireClient(item: Types.GunWeapon, targets: {BasePart}): boolean
	local part = targets[1]
	return part and isPartValid(part)
end

local function beforeHitAnything(_, round: Types.Round, hitPart: BasePart): boolean
	return isPartValid(hitPart)
end

type PoltInfo = {
	LastTime: number,
	PoltPhase: number,
	Attacker: Types.Participant,
}

local poltedProps: {[Types.Prop]: PoltInfo} = {}

local function beforeHitProp(_, round: Types.Round, hitProp: Types.Prop | Types.Interactable, params: Types.DamageParams): boolean
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
		local params = ExplosionParams.new({
			Damage = 10,
			FalloffBegin = 0,
			FalloffEnd = 15,
			Pressure = 50000,
			VisualRadius = 15,

			BeforeHitParticipant = function(_, _, hitParticipant: Types.Participant): boolean
				return hitParticipant ~= info.Attacker
			end,
		}, propRoot.Position, info.Attacker)
		Combat.CreateExplosion(prop.Round, params)
		return
	end

	PlaySound(7129285090, nil, prop.Model, {
		SoundGroup = SoundService.AllSounds :: SoundGroup,
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

local item: Types.GunWeaponDefinition = {
	Kind = "Gun" :: "Gun",
	Name = "Poltergeist",
	Description = "Attaches thrusters to props, blasting them towards others.",
	Icon = "rbxassetid://103677163409705",

	IsEvilItem = true,

	Model = ReplicatedStorage.Assets.WeaponModels.Poltergeist,

	LaserColor = Color3.new(),

	HoldAnimation = "rbxassetid://10247380824",

	Slot = 8,
	MaxStock = 2,
	CreditCost = 1,
	CanDrop = true,

	Damage = 0,

	Spread = 0,

	AttackInterval = 3,
	ReloadTime = 0,
	AmmoType = Ammo["Poltergeist"],

	RecoilX = 0,
	RecoilY = 0,

	PreRenderClient = preRenderClient,
	BeforePrimaryFireClient = beforePrimaryFireClient,

	BeforeHitAnything = beforeHitAnything,
	BeforeHitProp = beforeHitProp,
}

return item