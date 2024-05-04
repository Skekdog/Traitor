--!strict
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandlerTypes = require(ReplicatedFirst.RoundHandlerTypes)
local Adapters = require(ServerScriptService.RoundHandler.Adapters)
local API = require(ReplicatedFirst.API)

type BeforeHitFunction = (attacker: RoundHandlerTypes.Participant, target: RoundHandlerTypes.Participant) -> ()
export type AmmoType = "Assault Rifle" | "SMG" | "Pistol" | "Deagle"
export type Weapon = {
    Name: string,
    Description: string,

    Slot: number,
    CanDrop: boolean?,

    DamageHead: number,
    DamageBody: number,
    DamageLimb: number,

    FalloffStart: number,
    FalloffEnd: number,
    FalloffMultiplier: number,

    ExplosionInfo: ExplosionInfo?,

    CanAim: boolean?,
    AimFOV: number,
    AimSensitivityMultiplier: number,

    HasScope: boolean?,
    ScopeRequired: boolean?, -- Required to be scoped in to shoot

    FireTime: number, -- Delay between firing
    BulletsPerShot: number,
    ProjectileBase: PVInstance,

    ReloadTime: number,
    MaxReserve: number,
    MagazineSize: number,
    AmmoType: AmmoType?,

    BeforeHit: BeforeHitFunction?,

    Model: Model,
}

export type ExplosionInfo = {
    Radius: number,
    Pressure: number,
    Damage: number?,
    BeforeHit: BeforeHitFunction?,
    FalloffStart: number?,
    FalloffEnd: number?,
    FalloffMultiplier: number?,
}

local module = {}

local function spawnProjectile(weapon: Weapon)
    local projectile = weapon.ProjectileBase:Clone()
end

local function calculateDamage(attacker: RoundHandlerTypes.Participant?, weapon: Weapon, partName: string, distance: number): number
    local damage
    if partName == "Head" then
        damage = weapon.DamageHead
    elseif partName == "HumanoidRootPart" or partName:match("Torso") then
        damage = weapon.DamageBody
    else
        damage = weapon.DamageLimb
    end

    if distance >= weapon.FalloffStart then
        damage *= API.LerpNumber(1, weapon.FalloffMultiplier, (distance - weapon.FalloffStart) / weapon.FalloffEnd)
    end

    if attacker then
        damage *= Adapters.CalculateDamageModifier(attacker.Karma)
    end

    return damage
end

-- Weapon may be nil if it is e.g. an explosive barrel
function module.CreateExplosion(position: Vector3, explosionInfo: ExplosionInfo, attacker: RoundHandlerTypes.Participant?, weapon: Weapon?): ()
    local explosion = Instance.new("Explosion")
    explosion.BlastRadius = explosionInfo.Radius
    explosion.BlastPressure = explosionInfo.Pressure
    explosion.DestroyJointRadiusPercent = 0
    explosion.ExplosionType = Enum.ExplosionType.NoCraters

    explosion.Parent = workspace
end

return module