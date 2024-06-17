local Types = require(script.Parent.Parent.RoundHandler.Types)

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
    MaxReserve: number,
    MagazineSize: number,
    AmmoType: AmmoType?,
}
type ProjectileInfo = {
    Base: PVInstance,
    Speed: number,
}

export type Entity = Types.Participant | Types.Prop

export type AmmoType = "Shotgun" | "Scout" | "Assault Rifle" | "SMG" | "Deagle"
export type WeaponName = string
export type Weapon = {
    Kind: "Weapon",
    Name: string,
    Description: string,

    Slot: number,
    CanDrop: boolean,

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

    Model: Model,
    FiredSound: Sound,
    ReloadSound: Sound?,

    BeforeHitParticipant: BeforeHitParticipantFunction?,
    BeforeHitCorpse: BeforeHitCorpseFunction?,
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

return {}