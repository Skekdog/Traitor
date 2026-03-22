local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local Server = require(ReplicatedStorage.API.Item.Behaviour.Server)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)

local BASE_DAMAGE = 25
local BASE_RADIUS = 20
local BASE_PRESSURE = 10000

local POWER_SCALE_RATE = 2 -- 1 power every half second

local PROJECTILE = ReplicatedStorage.Assets.Projectiles.SimulatedBullet
local PROJECTILE_SIZE_BASE = PROJECTILE.Size

local projectiles: {BasePart} = {}

local model = ReplicatedStorage.Assets.ItemModels["Five-Seven"]:Clone()
model.Name = "Grow"
model.Parent = ReplicatedStorage.Assets.ItemModels

local Grow = Gun({
	Name = "Grow",
    Description = "Perfectly balanced, as all things should be.",
    IconContent = Content.none,

    ItemGroup = ItemGroups.Secondary,

    Damage = 20,

    Spread = 0.01,

    AimSpreadMultiplier = 0.1,

    PrimaryInterval = 0.6,
    ReloadDuration = 1,
    AmmoDefinition = Ammo["Mil-Spec"],

    ImpulseForce = 25,

    Model = model,
    HoldAnimation = Content.fromAssetId(9253211833),
    AimAnimation = Content.fromAssetId(18691552315),
    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired["Five-Seven"],
    ReloadSound = ReplicatedStorage.Assets.ItemSounds.Reload["Five-Seven"],

    MaxBounces = 3,
    ShouldPlayersStopBounces = true,

    OnProjectileDespawn = function(_, projectile, participant): ()
        local power = projectile:GetAttribute("Power") :: number? or 0

        if power < 0.25 then
            return
        end

        Server.CreateExplosion(participant.Round, ExplosionParams.new({
            Pressure = power * BASE_PRESSURE,
            Attacker = participant,
            Damage = power * BASE_DAMAGE,
            FalloffEnd = power * BASE_RADIUS,
            FalloffStart = 0,
            VisualRadius = power * BASE_RADIUS,
        }, GetPrimaryPart(projectile).Position))

        return
    end,

    OnProjectileSpawn = function(_, projectile): ()
        assert(projectile:IsA("BasePart"))

        table.insert(projectiles, projectile)

        projectile.Destroying:Connect(function()
            table.remove(projectiles, assert(table.find(projectiles, projectile)))
        end)
    end,

    Projectile = PROJECTILE,
    IsProjectileSimulated = true,
    ProjectileSpeed = 75,

    RecoilX = 0.2,
    RecoilY = 1.0,
})

RunService.PostSimulation:Connect(function(dt)
    for _, projectile in projectiles do
        local power = (projectile:GetAttribute("Power") :: number? or 0) + POWER_SCALE_RATE * dt
        projectile:SetAttribute("Power", power)

        projectile.Size += PROJECTILE_SIZE_BASE.Unit * POWER_SCALE_RATE * dt
    end
end)

return table.freeze(Grow)