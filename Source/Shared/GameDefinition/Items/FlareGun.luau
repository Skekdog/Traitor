local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fire = require(ReplicatedStorage.API.Fire)
local ItemGroups = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemGroups)
local ItemKillHighlights = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemKillHighlights)
local Ammo = require(script.Parent.Ammo)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function models(name: string): BasePart
    return ReplicatedStorage.Assets:WaitForChild("WeaponModels"):WaitForChild(name) :: BasePart
end

local function firedSounds(name: string): Sound
    return (ReplicatedStorage.Assets:WaitForChild("WeaponSounds"):WaitForChild("Fired"):WaitForChild(name) :: Sound)
end

local function projectiles(name: string): BasePart
    return ReplicatedStorage.Assets:WaitForChild("Projectiles"):WaitForChild(name) :: BasePart
end

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

local item: Types.GunWeaponDefinition = {
	Kind = "Gun" :: "Gun",
    Name = "Flare Gun",
    Description = "Will set things it hits on fire. Can be used to burn corpses, preventing others from discovering them.",
    Icon = "rbxassetid://444145395",
    CreditCost = 1,
    MaxStock = 1,

    ImpulseForce = 5,

    IsEvilItem = true,

    ItemGroup = ItemGroups.RoleUtility,
    CanDrop = true,

    Damage = {
        Head = 15,
        Body = 10,
        Limb = 5,
    },

    AmmoType = Ammo.Flare,

    HasMuzzleFlash = true,

    Spread = 0.015,

    AttackInterval = 0.25,
    ReloadTime = 0,
    MagazineSize = 6,

    Model = models("Flare Gun"),
    HoldAnimation = "rbxassetid://9253211833",
    AimAnimation = "rbxassetid://18691552315",
    AttackSound = firedSounds("Flare Gun"),

    Projectile = projectiles("Flare"),
    ProjectileSpeed = 280,

    AimFOV = 60,
    AimSpreadMultiplier = 0.3,

    BeforeHitParticipant = function(item, round, target: Types.Participant, params: Types.DamageParams): boolean
        ItemKillHighlights(highlight1, highlight2)(item, round, target, params)

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

    BeforeHitProp = function(_, _, target: Types.Prop | Types.Interactable, params: Types.DamageParams): boolean
        local attacker = params.Attacker
        assert(attacker)

        if Fire.IsBurning(target.Model) then
            return true
        end

        Fire.Ignite(target.Model, attacker)

        task.delay(math.random(9, 11), function()
            if target.Model:HasTag("Corpse") then
                target.Model:Destroy()
            else
                Fire.Extinguish(target.Model)
            end
        end)

        return true
    end,

    RecoilX = 0.8,
    RecoilY = 1.2,
}

return item