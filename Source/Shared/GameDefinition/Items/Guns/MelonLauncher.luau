local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local BehaviourTypes = require(ReplicatedStorage.API.Item.Behaviour.BehaviourTypes)

local MelonLauncher = {}

local PRESSURE = 75000
local RADIUS = 15
local PROJECTILE_FORCE = 75
local PROJECTILE = ReplicatedStorage.Assets.Projectiles.Watermelon

local function reduceAmount(info: Types.ExplosionInfo | Types.Item, params: Types.DamageParams, hitParticipant: Types.Participant): boolean
	if hitParticipant == params.Attacker then
		params.Amount /= 5
	end
	return true
end

local function BeforeHitAnything(_, params: Types.DamageParams): boolean
	local Combat = require(ReplicatedStorage.API.Combat)
	assert(params.Attacker and params.HitPosition)
	Combat.MakeExplosion({
		Attacker = params.Attacker,
		Position = params.HitPosition,
		Damage = 50,
		FalloffEnd = RADIUS,
		FalloffStart = 5,
		Pressure = PRESSURE,

		BeforeHitParticipant = reduceAmount,
		FilterImpulse = function(_: Types.ExplosionInfo, participant: Types.Participant): boolean?
			if participant == params.Attacker then
				return false
			end
			return true
		end,
	})
	return true
end

local function PrimaryFireClient(item: Types.Item, origin: Vector3, direction: Vector3): boolean | string | {string}
	local Client = require(ReplicatedStorage.API.Item.Behaviour.Client)
	local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
	local Impulse = require(ReplicatedStorage.API.Impulse)

	item.IsProjectileSimulated = false
	local result = Client.PrimaryFire(item, origin, direction, true)
	item.IsProjectileSimulated = true

	;(function(): boolean | string | {string}
		if result ~= true then
			return result
		end

		local request = item:GetServerData("Primary") :: BehaviourTypes.Request
		if not request then
			return true
		end

		local hitscan = request[1]
		if not hitscan then
			return true
		end

		local distance = (origin - hitscan.Position).Magnitude
		local speed = PROJECTILE_FORCE

		local duration = distance / speed

		task.delay(duration, function()
			local root = LocalCharacter.RootPart()
			if not root then
				return
			end

			if (root.Position - hitscan.Position).Magnitude > RADIUS then
				return
			end

			local impulse = (root.Position - hitscan.Position).Unit * PRESSURE / 1000
			Impulse.ApplyImpulse(root, impulse, true, root:GetClosestPointOnSurface(hitscan.Position))
		end)

		return true
	end)()

	item:SetServerData("Primary", nil)

	return Client.PrimaryFire(item, origin, direction)
end

MelonLauncher.Item = Gun({
	Name = "MelonLauncher",
	DisplayName = "Melon Launcher",
	Description = "Launches explosive melons.",
	IconContent = Content.fromAssetId(4793387432),

	Model = ReplicatedStorage.Assets.ItemModels.MelonLauncher,
	HoldAnimation = Content.fromAssetId(10247529531),

	IsAimable = false,

	PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired["Melon Launcher"],

	Cost = 1,
	MaxStock = 1,

	IsEvilItem = true,

	ItemGroup = ItemGroups.RoleWeapon,

	IsProjectileSimulated = true,

	Projectile = PROJECTILE,
	ProjectileSpeed = PROJECTILE_FORCE,

	Damage = 50,
	Spread = 0.01,

	AmmoDefinition = Ammo.MelonLauncher,
	PrimaryInterval = 1.5,

	RecoilX = 10,
	RecoilY = 10,

	BeforeHitAnything = BeforeHitAnything,
	BeforeHitParticipant = reduceAmount,

	PrimaryFireClient = PrimaryFireClient,
})

return MelonLauncher