local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Audio = require(ReplicatedStorage.API.Audio)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Types = require(ReplicatedStorage.API.Types)
local Ragdoll = require(ReplicatedStorage.Shared.RoundRule.Ragdoll)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)

local SealGun = {}

local function onHitClient(): ()
	local Camera = require(ReplicatedStorage.API.Camera)
	Camera.EnterAnimationView()
	task.delay(3, Camera.EnterFirstPerson)
end

local function beforeHitAnything(_, params: Types.DamageParams): boolean
	local projectile = params.Projectile
	assert(projectile)

	if projectile:GetAttribute("DidHit") then
		return true
	end

	projectile:SetAttribute("DidHit", true)
	task.delay(5, ForEachPart, projectile, function(part: BasePart)
		part.Anchored = true
		TweenService:Create(part, TweenInfo.new(1), {
			Transparency = 1,
		}):Play()
	end)

	task.delay(6, projectile.Destroy, projectile)

	return true
end

local SLIP_SOUND = Audio.MakeSound({
	Content = Content.fromAssetId(129432532096499),
	RolloffStart = 20,
	RolloffEnd = 30,
})

local function beforeHitParticipant(item: Types.Item, params: Types.DamageParams, participant: Types.Participant): boolean
	local projectile = params.Projectile
	assert(projectile)

	local char = participant:GetCharacter()
	if not char or projectile:GetAttribute("Hit_" .. char.Name) then
		return false
	end

	projectile:SetAttribute("Hit_" .. char.Name, true)

	if char.PrimaryPart then
		Audio.PlayIn(SLIP_SOUND, char.PrimaryPart)
	end

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

	ProjectileSpeed = 30,
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
	BeforeHitAnything = beforeHitAnything,

	BeforeHitProp = function() return false end, -- Otherwise it keeps hitting props and destroys them

	OnHitClient = onHitClient,

	PregameDisable = true,
})

SealGun.Item = item

return table.freeze(SealGun)