
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

local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)
local Ammo = require(script.Parent.Ammo)
local MagnetoStick = require(script.Parent.MagnetoStick)
local NewtonLauncher = require(script.Parent.NewtonLauncher)
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

local function preRenderClient(item: Types.AnyItem, dt: number): ()
	assert(item.Kind == "Gun")
	local map = workspace:FindFirstChild("Map")
	if not map then
		return
	end

	local props = map:FindFirstChild("Props")
	if not props then
		return
	end

	local result = raycast(assert(LocalCharacter.Character()), MAX_RANGE)
	if not result then
		return
	end

	local instance = result.Instance :: BasePart
	if instance:IsDescendantOf(props) and NewtonLauncher.CanFling(instance) then
		item.Definition.LaserColor = Color3.new(0, 1, 0)
	else
		item.Definition.LaserColor = Color3.new(1, 0, 0)
	end
end

local function beforePrimaryFireClient(item: Types.GunWeapon, targets: {BasePart}): boolean
	local part = targets[1]
	local map = workspace:FindFirstChild("Map")
	if not map then
		return false
	end

	local props = map:FindFirstChild("Props")
	if not props then
		return false
	end

	return part and part:IsDescendantOf(props) and NewtonLauncher.CanFling(part)
end

local function beforeHitAnything(_, round: Types.Round, hitPart: BasePart): boolean
	return hitPart:IsDescendantOf(round:GetMap().Props)
end

type PoltInfo = {
	LastTime: number,
	PoltPhase: number,
	Attacker: Types.Participant,
}

local poltedProps: {[Types.MapProp]: PoltInfo} = {}

local function beforeHitProp(_, round: Types.Round, hitProp: Types.Prop, params: Types.DamageParams): boolean
	assert(params.Attacker)

	if hitProp.Kind ~= "MapProp" then
		return false
	end

	if not NewtonLauncher.CanFling(hitProp.Model) then
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

local function doPropPolt(prop: Types.MapProp, info: PoltInfo): ()
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

	for _, participant in prop.Round:GetParticipants() do
		assert(participant)
		local distance = participant.Player:DistanceFromCharacter(prop.Model.Position)
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

	MagnetoStick.SetLastHeldBy(prop, info.Attacker.Player)

	local direction = (prop.Model.Position - root.Position).Unit
	NewtonLauncher.Fling(prop.Model, -direction * 1000 * prop.Model.AssemblyMass / 18)

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
		}, prop.Model.Position, info.Attacker)
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

	IsBadGuyItem = true,

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