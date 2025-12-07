export type ValidatePrimaryFire = "PrimaryFireDisabled" | "TargetTooFar" | "ShooterTooFar" | "StaticObscured" | "Success" | "OtherError"

export type ValidateRaycastResult = "TargetTooFar" | "StaticObscured" | "Success"

export type ValidateItemUsageResult = "PreGame" | "Reloading" | "Dead" | "NotEnoughAmmo" | "FiringTooFast" | "NotEquipped" | "Success" | "UnknownItem" | "NotInRound" | ValidatePrimaryFire | "AlternateFireDisabled"

export type RaycastInfo = {
	Destination: Vector3,
	HitPart: BasePart?,
	HitPartCenterPosition: Vector3?,
	Normal: Vector3?,
	RelativeHitCFrame: CFrame?,
}

export type PrimaryFireBaseRequest = {
	ItemName: string,
	Origin: Vector3,
}

export type AlternateFireBaseRequest = PrimaryFireBaseRequest

export type PrimaryFireRaycastRequest = PrimaryFireBaseRequest & {
	Kind: "PrimaryFireRaycastRequest",
	Raycasts: {RaycastInfo},
}

export type PrimaryFireThrowRequest = PrimaryFireBaseRequest & {
	Kind: "PrimaryFireThrowRequest",
	Direction: Vector3,
}

export type PrimaryFireItemRequest = PrimaryFireBaseRequest & {
	Kind: "PrimaryFireItemRequest",
	Direction: Vector3,
}

export type AlternateFireItemRequest = AlternateFireBaseRequest & {
	Kind: "AlternateFireItemRequest",
	Direction: Vector3,
}

export type PrimaryFireRequest = PrimaryFireRaycastRequest | PrimaryFireThrowRequest | PrimaryFireItemRequest

export type AlternateFireRequest = AlternateFireItemRequest

return nil