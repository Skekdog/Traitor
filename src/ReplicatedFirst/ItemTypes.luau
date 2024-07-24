local Types = require(script.Parent.RoundHandler.Types)

type OnUnequipFunction = (player: Player) -> ()

export type AmmoType = "Shotgun" | "Scout" | "Assault Rifle" | "SMG" | "Deagle"
type BeforeHitParticipantFunction = (attacker: Types.Participant?, target: Types.Participant, willDie: boolean?, hitPartName: string) -> boolean?
type BeforeHitPropFunction = (attacker: Types.Participant?, target: Types.Prop, willDestroy: boolean?, hitPartName: string) -> boolean?
type BeforeHitCorpseFunction = (attacker: Types.Participant?, part: BasePart) -> ()

type DamageInfo = number | {
    Head: number,
    Body: number,
    Limb: number,
}

export type ExplosionInfo = {
    Kind: "Explosion",
    Radius: number,
    Pressure: number,
    Damage: number,
    BeforeHitParticipant: BeforeHitParticipantFunction?,
    BeforeHitCorpse: BeforeHitCorpseFunction?,
    BeforeHitProp: BeforeHitPropFunction?,
    OnExplode: ((self: ExplosionInfo, position: Vector3, attacker: Types.Participant?) -> ())?,
    FalloffStart: number?,
    FalloffEnd: number?,
    FalloffMultiplier: number?,
}

export type Item = GenericItem | Weapon

export type GenericItem = {
    Kind: "Item",
    Instance: BasePart,
    Base: ItemDefinition,
}

export type Weapon = GunWeapon | GrenadeWeapon | MeleeWeapon

export type GunWeapon = {
    Kind: "Gun",
    Instance: BasePart,
    Base: GunDefinition,

    CurrentAmmo: number,
    LastFireTime: number,
    LastFireAttempt: number, -- For empty clip sound
    Reloading: thread?,
}

export type GrenadeWeapon = {
    Kind: "Grenade",
    Instance: BasePart,
    Base: GrenadeDefinition,
}

export type MeleeWeapon = {
    Kind: "Melee",
    Instance: BasePart,
    Base: MeleeDefinition,

    LastFireTime: number,
}

export type ItemDefinition = {
    Kind: "Item",
    Name: string,
    Description: string?,
    Icon: string?,

    Slot: number,
    CanDrop: boolean,

    Model: BasePart,
    HoldAnimation: number?,

    Toggled: boolean?,
    ToggledAlt: boolean?,
    OnEquipClient: (() -> ())?,
    OnUnequipClient: (() -> ())?,
    
    PrimaryFire: ((Types.Participant, cameraRay: Ray) -> ())?,
    AlternateFire: ((Types.Participant, cameraRay: Ray) -> ())?,
    OnUnequip: OnUnequipFunction?,
}

export type WeaponDefinition = GunDefinition | GrenadeDefinition | MeleeDefinition

export type GunDefinition = {
    Kind: "Gun",
    Name: string,
    Description: string?,
    Icon: string?,
    Slot: number,
    CanDrop: boolean,
    
    Model: BasePart,
    HoldAnimation: number,

    Damage: DamageInfo,

    FiredSound: Sound,
    ReloadSound: Sound?,

    FalloffStart: number,
    FalloffEnd: number,
    FalloffMultiplier: number,

    FireTime: number,
    ReloadTime: number,
    MagazineSize: number?,
    AmmoType: AmmoType?,

    AimFOV: number,
    HasScope: boolean?,
    ScopeRequired: boolean?,
    AimSpreadMultiplier: number,

    ProjectileBase: BasePart,
    ProjectileSpeed: number,

    RecoilX: number,
    RecoilY: number,
    Spread: number,

    BulletsPerShot: number?,

    BeforeHitCorpse: BeforeHitCorpseFunction?,
    BeforeHitParticipant: BeforeHitParticipantFunction?,
    BeforeHitProp: BeforeHitPropFunction?,
}

export type GrenadeDefinition = {
    Kind: "Grenade",
    Name: string,
    Description: string?,
    Icon: string?,
    Slot: number,
    CanDrop: boolean,

    Model: BasePart,
    HoldAnimation: number,

    ExplosionInfo: ExplosionInfo,
    Fuse: number,
    
    ProjectileForce: number,
    Spread: number,

    FiredSound: Sound,

    BeforeHitParticipant: BeforeHitParticipantFunction?,
    BeforeHitCorpse: BeforeHitCorpseFunction?,
    BeforeHitProp: BeforeHitPropFunction?,
}

export type MeleeDefinition = {
    Kind: "Melee",
    Name: string,
    Description: string?,
    Icon: string?,
    Slot: number,
    CanDrop: boolean,

    Model: BasePart,
    HoldAnimation: number,
    HitAnimation: number,

    MaxDistance: number,
    Damage: number,
    FireTime: number,
    FiredSound: Sound,

    BeforeHitParticipant: BeforeHitParticipantFunction?,
    BeforeHitCorpse: BeforeHitCorpseFunction?,
    BeforeHitProp: BeforeHitPropFunction?,
}

return {}