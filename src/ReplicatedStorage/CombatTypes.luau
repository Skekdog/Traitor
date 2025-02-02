export type ValidateRaycastResult = "TargetTooFar" | "ShooterTooFar" | "StaticObscured" | "Success" | "OtherError"

export type ValidateItemUsageResult = "Dead" | "NotEnoughAmmo" | "FiringTooFast" | "NotEquipped" | "Success" | "UnknownItem" | "NotInRound" | ValidateRaycastResult

export type Shot = {
	Destination: Vector3,
	HitPart: BasePart?,
	HitPartCenterPosition: Vector3?,
}
			
export type PrimaryFireRequest = {
	Origin: Vector3,
	ItemName: string,

	Shots: {Shot},
}

return nil