local Ammo = require(script.Parent.Ammo)
local Types = require(script.Parent.Parent.RoundRule.Types)

local function models(name: string): BasePart
    return game:GetService("ReplicatedStorage"):WaitForChild("WeaponModels"):WaitForChild(name) :: BasePart
end

local guns: {[string]: Types.GunWeaponDefinition} = {}
guns.HUGE = {
    Kind = "Gun" :: "Gun",
    Name = "HUGE",

    Slot = 3,
    CanDrop = true,
    
    Spread = 2,

    Damage = {
        Head = 15,
        Body = 10,
        Limb = 5,
    },

    FalloffStart = 35,
    FalloffEnd = 80,
    FalloffMultiplier = 0.5,

    AimFOV = 60,
    AimSpreadMultiplier = 0.3,

    FireTime = 0.01,
    ReloadTime = 0,
    MagazineSize = 250,

    ProjectileBase = bullet,
    ProjectileSpeed = 140,

    Model = models("HUGE"),
    HoldAnimation = "12498608892",
    AimAnimation = "18691844030",

    FiredSound = firedSounds("HUGE"),
    ReloadSound = "",

    RecoilX = 1,
    RecoilY = 2,

    AmmoType = Ammo.HUGE,
}

local allItems: {[string]: Types.AnyItemDefinition} = {}

for i, v in guns do
    allItems[i] = v
end

return allItems