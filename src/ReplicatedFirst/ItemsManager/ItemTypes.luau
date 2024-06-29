local Types = require(script.Parent.Parent.RoundHandler.Types)

type OnUnequipFunction = (player: Player) -> ()
export type ItemDefinition = {
    Kind: "Item",
    Name: string,
    Description: string,
    Icon: string?,

    Slot: number,
    CanDrop: boolean,

    Model: MeshPart?,

    PrimaryFire: ((Types.Participant, cameraRay: Ray) -> ())?,
    AlternateFire: ((Types.Participant, cameraRay: Ray) -> ())?,
    OnUnequip: OnUnequipFunction?,
}

export type Item = {
    Kind: "Item",
    Base: ItemDefinition,
    Instance: PVInstance,
}

export type Weapon = {
    Kind: "Weapon",
    Base: WeaponDefinition,
    Instance: PVInstance,
    CurrentAmmo: number,
    LastFireTime: number,
    Reloading: thread?,
}

export type AmmoType = "Shotgun" | "Scout" | "Assault Rifle" | "SMG" | "Deagle"
type BeforeHitParticipantFunction = (attacker: Types.Participant?, target: Types.Participant, willDie: boolean?, hitPartName: string) -> boolean?
type BeforeHitPropFunction = (attacker: Types.Participant?, target: Types.Prop, willDestroy: boolean?, hitPartName: string) -> boolean?
type BeforeHitCorpseFunction = (attacker: Types.Participant?, part: BasePart) -> ()

type AimInfo = {
    FOV: number,
    HasScope: boolean?,
    ScopeRequired: boolean?,
    SpreadMultiplier: number,
}
type DamageInfo = number | {
    Head: number,
    Body: number,
    Limb: number,
}
type MultiUseInfo = {
    FireTime: number, -- Delay between firing
    ReloadTime: number,
    MagazineSize: number?,
    AmmoType: AmmoType?,
}
type ProjectileInfo = {
    Base: PVInstance,
    Speed: number,
}

export type ExplosionInfo = {
    Kind: "Explosion",
    Radius: number,
    Pressure: number,
    Damage: number,
    BeforeHitParticipant: BeforeHitParticipantFunction?,
    BeforeHitCorpse: BeforeHitCorpseFunction?,
    FalloffStart: number?,
    FalloffEnd: number?,
    FalloffMultiplier: number?,
}

export type WeaponDefinition = {
    Name: string,
    Description: string,
    Icon: string?,

    Slot: number,
    CanDrop: boolean,

    Model: MeshPart?,

    PrimaryFire: ((Types.Participant, cameraRay: Ray) -> ())?,
    AlternateFire: ((Types.Participant, cameraRay: Ray) -> ())?,
    OnUnequip: OnUnequipFunction?,

    Kind: "Weapon",
    Damage: DamageInfo,

    FalloffStart: number,
    FalloffEnd: number,
    FalloffMultiplier: number,

    ExplosionInfo: ExplosionInfo?,
    FuseTime: number?,

    AimInfo: AimInfo | false,

    Recoil: number,
    Spread: number,
    
    MultiUse: MultiUseInfo | false,
    BulletsPerShot: number?,

    ProjectileInfo: ProjectileInfo | false,

    FiredSound: Sound,
    ReloadSound: Sound?,

    BeforeHitParticipant: BeforeHitParticipantFunction?,
    BeforeHitCorpse: BeforeHitCorpseFunction?,
}

return {}