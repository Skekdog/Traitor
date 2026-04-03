local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fire = require(ReplicatedStorage.API.Fire)
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local ItemKillHighlights = require(ReplicatedStorage.API.Item.Behaviour.KillHighlights)
local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)
local Types = require(ReplicatedStorage.API.Types)

local highlight1 = {
    Title = "To The Rescue",
    Description = "%s used their flares to signal for %d deaths.",
    Priority = 2,
    Threshold = 2,
}

local highlight2 = {
    Title = "Flare Indicates Fire",
    Description = "%s taught %d people about the danger of wearing flammable clothing.",
    Priority = 4,
    Threshold = 4,
}

local FlareGun = Gun ({
    Name = "Flare Gun",
    Description = "Will set things it hits on fire. Can be used to burn corpses, preventing others from discovering them.",
    IconContent = Content.fromAssetId(444145395),

    Cost = 1,
    MaxStock = 1,

    ImpulseForce = 5,

    IsSuspicious = true,

    ItemGroup = ItemGroups.RoleUtility,

    Damage = {
        Head = 15,
        Body = 10,
        Limb = 5,
    },

    AmmoDefinition = Ammo.Flare,

    Spread = 0.015,

    PrimaryInterval = 0.25,

    Model = ReplicatedStorage.Assets.ItemModels["Flare Gun"],
    HoldAnimation = Content.fromAssetId(9253211833),
    AimAnimation = Content.fromAssetId(18691552315),
    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired["Flare Gun"],

    Projectile = ReplicatedStorage.Assets.Projectiles.Flare,
    ProjectileSpeed = 280,

    AimFOV = 60,
    AimSpreadMultiplier = 0.3,

    BeforeHitParticipant = function(item, params: Types.DamageParams, target: Types.Participant): boolean
        ItemKillHighlights(highlight1, highlight2)(item, params, target)

        local attacker = params.Attacker
        assert(attacker)

        local character = target:GetCharacter()
        assert(character)

        if Fire.IsBurning(character) then
            return true
        end

        Fire.Ignite(character, attacker)

        task.delay(math.random(9, 11), Fire.Extinguish, character)

        return true
    end,

    BeforeHitProp = function(_, params: Types.DamageParams, target: Types.Prop): boolean
        local attacker = params.Attacker
        assert(attacker)

        if Fire.IsBurning(target.Model) then
            return true
        end

        Fire.Ignite(target.Model)

        if target.Model:HasTag("Corpse") then
            if not attacker:GetRole().Definition.CanDoSuspiciousActions then
                attacker:SetFreeKill("flared a corpse")
            end
        end

        task.delay(math.random(9, 11), function()
            if target.Model:HasTag("Corpse") then
                target.Model:Destroy()
            else
                Fire.Extinguish(target.Model)
            end
        end)

        return true
    end,

    BeforeHitAnything = function(_, params: Types.DamageParams, round: Types.Round): boolean
        assert(params.HitPosition, params.HitPart)

        local hitPart = params.HitPart

        if GetMapObject(hitPart, "Prop") or GetMapObject(hitPart, "Character") then
            return true
        end

        local part = CreateEmptyPart(CFrame.new(params.HitPosition))
        part.Size = Vector3.one
        part.Parent = workspace.Projectiles

        Fire.Ignite(part)

        task.delay(math.random(9, 11), Fire.Extinguish, part)

        return true
    end,

    RecoilX = 0.8,
    RecoilY = 1.2,
})

return table.freeze(FlareGun)