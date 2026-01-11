export type ValidateUsageResult =
	| "Pregame"
	| "Reloading"
	| "Dead"
	| "NotEnoughAmmo"
	| "FiringTooFast"
	| "NotEquipped"
	| "UnknownItem"
	| "NotInRound"
	| "AlternateFireDisabled"
	| "PrimaryFireDisabled"
	| "OriginTooFar"
	| "TargetTooFar"
	| "StaticObscured"
	| "OtherError"
	| "Success"

export type RaycastInfo = {
	Destination: Vector3,
	HitPart: BasePart?,
	HitPartCenterPosition: Vector3?,
	Normal: Vector3?,
	RelativeHitCFrame: CFrame?,
}

export type Request = {
	Action: "Primary" | "Alternate",
	ItemName: string,
	Direction: Vector3,
	Origin: Vector3,
	Raycasts: {RaycastInfo},
}

return nil