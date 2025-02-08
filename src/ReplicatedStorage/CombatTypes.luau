export type ValidateRaycastResult = "TargetTooFar" | "ShooterTooFar" | "StaticObscured" | "Success" | "OtherError"

export type ValidateItemUsageResult = "Reloading" | "Dead" | "NotEnoughAmmo" | "FiringTooFast" | "NotEquipped" | "Success" | "UnknownItem" | "NotInRound" | ValidateRaycastResult

export type RaycastInfo = {
	Destination: Vector3,
	HitPart: BasePart?,
	HitPartCenterPosition: Vector3?,
	Normal: Vector3?,
}

export type PrimaryFireBaseRequest = {
	ItemName: string,
	Origin: Vector3,
}

export type PrimaryFireRaycastRequest = PrimaryFireBaseRequest & {
	Kind: "PrimaryFireRaycastRequest",
	Raycasts: {RaycastInfo},
}

export type PrimaryFireThrowRequest = PrimaryFireBaseRequest & {
	Kind: "PrimaryFireThrowRequest",
	Direction: Vector3,
}

export type PrimaryFireRequest = PrimaryFireRaycastRequest | PrimaryFireThrowRequest

return nil