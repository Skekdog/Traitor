local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Types = require(ReplicatedStorage.API.Types)
local Ragdoll = require(ReplicatedStorage.Shared.RoundRule.Ragdoll)

local SealGun = {}

local function beforeHitParticipant(item: Types.Item, params: Types.DamageParams, participant: Types.Participant): boolean
	if not item.Extras.SealGunHits then
		item.Extras.SealGunHits = {
			Params = params,
			Hits = {},
		}
	end

	local char = participant:GetCharacter()
	if not char or table.find(item.Extras.SealGunHits.Hits, char) then
		return false
	end

	table.insert(item.Extras.SealGunHits.Hits, char)

	PlaySound(129432532096499, nil, char.PrimaryPart, {
		RollOffMinDistance = 10,
		RollOffMaxDistance = 20,
	})

	Ragdoll.Ragdoll(participant, char)

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

	PregameDisable = true,
})

SealGun.Item = item

return SealGun