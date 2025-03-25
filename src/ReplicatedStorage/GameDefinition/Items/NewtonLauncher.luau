local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(script.Parent.Ammo)
local MagnetoStick = require(script.Parent.MagnetoStick)
local Types = require(ReplicatedStorage.RoundRule.Types)

local beforeHit = function(weapon: Types.ItemBeforeHit, round: Types.Round, hit: Types.Participant | Types.Prop, params: Types.DamageParams): boolean
	assert(weapon.Kind == "Gun")

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

    if hit.Kind == "MapProp" then
        MagnetoStick.SetLastHeldBy(hit, attacker.Player)
    end

	part:ApplyImpulse(char:GetPivot().LookVector * 1000 * part.AssemblyMass / 18)

	return true
end

local item: Types.GunWeaponDefinition = {
	Kind = "Gun" :: "Gun",
    Name = "Newton Launcher",
    Description = "Flings anyone who is hit. Low inherent damage, but can be used to crush others with props or throw them off high ledges.",
    Icon = "rbxassetid://10243797417",

	Slot = 8,
    MaxStock = 2,
    CreditCost = 1,
    CanDrop = true,

    Damage = {
        Head = 8,
        Body = 4,
        Limb = 1,
    },

    Spread = 0.02,

    AttackInterval = 2,
    ReloadTime = 0,
    AmmoType = Ammo["Newton"],

    Model = ReplicatedStorage.WeaponModels["Newton Launcher"],
    HoldAnimation = "rbxassetid://10247380824",
    AimAnimation = "rbxassetid://18691831450",
    AttackSound = "rbxassetid://8561500387",
    ReloadSound = "",

    Projectile = ReplicatedStorage.Projectiles["Newton"],
    ProjectileSpeed = 300,

    RecoilX = 0,
    RecoilY = 0,

	BeforeHitParticipant = beforeHit,
	BeforeHitProp = beforeHit,
}

return item