local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local MakeGolden = require(ReplicatedStorage.API.MakeGolden)
local Types = require(ReplicatedStorage.API.Types)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local KillHighlights = require(ReplicatedStorage.API.Item.Behaviour.KillHighlights)

local killHighlight = {
    Title = "I'm The Guy With The Gun",
    Description = "%s swiftly brought down justice on their target.",
    Priority = 4,
    Threshold = 1,
    ScoreBonus = 2,
}

local GoldenGun = Gun({
	Name = "Golden Gun",
    Description = "Instantly kills any enemy. Not recommended for use against allies.",
    IconContent = Content.fromAssetId(10282780102),
    Cost = 1,
    MaxStock = 1,

    ItemGroup = ItemGroups.RoleWeapon,

    Damage = {
        Head = 0,
        Body = 0,
        Limb = 0,
    },

    AmmoDefinition = Ammo["Golden Bullet"],

    LaserColor = Color3.fromRGB(47, 47, 255),

    Projectile = ReplicatedStorage.Assets.Projectiles.GoldenBullet,
    ProjectileSpeed = 250,

    ImpulseForce = 50, -- :troll:

    Model = ReplicatedStorage.Assets.ItemModels["Golden Gun"],
    HoldAnimation = Content.fromAssetId(9253211833),
    AimAnimation = Content.fromAssetId(18691552315),
    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired["Golden Gun"],

    PrimaryInterval = 0.5,

    BeforeHitParticipant = function(item: Types.Item, params: Types.DamageParams, target: Types.Participant): boolean
        local attacker = params.Attacker
        assert(attacker)

        if attacker:IsDamageJustifiedAgainstParticipant(target) then
            KillHighlights(killHighlight)(item, params, target)

            MakeGolden(target)

            target:TryTakeDamage({
                Amount = math.huge,
                Attacker = attacker,
                Source = item,
                IsHeadshot = false,

                Origin = params.Origin,
                HitPosition = params.HitPosition,
                HitPart = params.HitPart,

                Projectile = params.Projectile,
            })
        else
            MakeGolden(attacker)
            attacker:TryTakeDamage({
                Amount = math.huge,
                Attacker = attacker,
                Source = item,
                IsHeadshot = false,

                Origin = params.Origin,
            })
        end

        return false
    end,
})

return GoldenGun