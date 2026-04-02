local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Impulse = require(ReplicatedStorage.API.Impulse)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local beforeHit = function(weapon: Types.Item, params: Types.DamageParams, hit: Types.Participant | Types.Prop): boolean
	local model = if hit.Kind == "Participant" then hit:GetCharacter() else hit.Model
	if not model then
		return true
	end

	local part = if model:IsA("BasePart") then model else model.PrimaryPart
	if not part then
		return true
	end

	local attacker = params.Attacker
	assert(attacker)

	local char = attacker:GetCharacter()
	if not char then
		return true
	end

    local force = ((params.Direction or Vector3.zero) + if hit.Kind == "Participant" then Vector3.yAxis else Vector3.zero) * 50

    if hit.Kind == "Participant" then
        force *= Vector3.new(2, 1, 2)
    end

    Impulse.ApplyImpulse(part, force, true, params.HitPosition, attacker)

	return true
end

local NewtonLauncher = Gun({
    Name = "Newton Launcher",
    Description = "Flings anything it hits. Low inherent damage, but can be used to crush others with props or throw them off high ledges.",
    IconContent = Content.fromAssetId(1491877109),

    IsSuspicious = true,

    IsAimable = false,

	ItemGroup = ItemGroups.RoleUtility,
    MaxStock = 2,
    Cost = 1,

    Damage = {
        Head = 8,
        Body = 4,
        Limb = 1,
    },

    PrimaryInterval = 2,
    AmmoDefinition = Ammo["Infinite"],

    Model = ReplicatedStorage.Assets.ItemModels["Newton Launcher"],
    HoldAnimation = Content.fromAssetId(132951688645757),
    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired["Newton Launcher"],

    Projectile = ReplicatedStorage.Assets.Projectiles["Newton"],
    ProjectileSpeed = 300,

    RecoilX = 0.1,
    RecoilY = 0.1,

	BeforeHitParticipant = beforeHit,
	BeforeHitProp = beforeHit,
})

local module = {}

module.Item = NewtonLauncher

return table.freeze(module)