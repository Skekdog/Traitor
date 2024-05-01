--hoowah
local ReplicatedFirst = game:GetService("ReplicatedFirst")

export type AmmoType = "Assault Rifle" | "SMG" | "Pistol" | "Deagle" | "None"
export type Weapon = {
    Name: string,
    Description: string,
    Slot: number,

    DamageHead: number,
    DamageBody: number,
    DamageLimb: number,

    FalloffStart: number,
    FalloffEnd: number,
    FalloffMultiplier: number,

    CanAim: boolean,
    AimFOV: number,
    AimSensitivityMultiplier: number,

    HasScope: boolean,
    ScopeRequired: boolean, -- Required to be scoped in to shoot

    FireTime: number, -- Delay between firing
    BulletsPerShot: number,

    ReloadTime: number,
    MaxReserve: number,
    MagazineSize: number,
    AmmoType: AmmoType,

    Model: Model,
}

local module = {}

local function spawnProjectile()

end

module.CalculateDamage(weapon: Weapon, partName: string, distance: number): number
    local damage = 0
    if partName == "Head" then
        damage = weapon.DamageHead
    elseif partName == "HumanoidRootPart" or partName:match("Torso") then
        damage = weapon.DamageBody
    else
        damage = weapon.DamageLimb
    end
end

return module