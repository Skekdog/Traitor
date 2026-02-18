local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Types = require(ReplicatedStorage.API.Types)
local Ragdoll = require(ReplicatedStorage.Shared.RoundRule.Ragdoll)

local SealGun = {}

local function onHitClient(): ()
	local Camera = require(ReplicatedStorage.API.Camera)
	Camera.EnterAnimationView()
	task.delay(3, Camera.EnterFirstPerson)
end

local function beforeHitParticipant(item: Types.Item, params: Types.DamageParams, participant: Types.Participant): boolean
	local projectile = params.Projectile
	assert(projectile)

	local char = participant:GetCharacter()
	if not char or projectile:GetAttribute("Hit_" .. char.Name) then
		return false
	end

	projectile:SetAttribute("Hit_" .. char.Name, true)

	PlaySound(129432532096499, nil, char.PrimaryPart, {
		RollOffMinDistance = 10,
		RollOffMaxDistance = 20,
	})

	Ragdoll.Ragdoll(participant, char)

	task.delay(3, Ragdoll.Unragdoll, char)

	return true
end

local item = Gun({
	Name = "Seal Gun",
	Description = "Silly seals slide seeking to slip someone asunder. P.S. Yes I know it's a sea lion sound.",
	IconContent = Content.fromAssetId(8788837799),

	Cost = 1,
	MaxStock = 2,

	Model = ReplicatedStorage.Assets.ItemModels["Seal Gun"],
	Projectile = ReplicatedStorage.Assets.Projectiles.Seal,

	MaxBounces = math.huge,
	ShouldPlayersStopBounces = false,
	IsProjectileSimulated = true,

	HoldAnimation = Content.fromAssetId(10247529531),

	ProjectileSpeed = 50,
	Spread = 0.01,

	CanHeadshot = false,
	Damage = 10,

	AmmoDefinition = Ammo.MelonLauncher,

	IsAimable = false,

	ItemGroup = ItemGroups.RoleWeapon,

	PrimaryInterval = 1.5,
	PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.Seal,

	RecoilX = 10,
	RecoilY = 10,

	BeforeHitParticipant = beforeHitParticipant,

	BeforeHitProp = function() return false end, -- Otherwise it keeps hitting props and destroys them

	OnHitClient = onHitClient,

	PregameDisable = true,
})

SealGun.Item = item

return SealGun