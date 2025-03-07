local LocalAnimation = require(script.Parent.LocalAnimation)
local WalkSpeed = require(script.Parent.WalkSpeed)

local isCrouching = false

local module = {}

function module.IsCrouching(): boolean
	return isCrouching
end

function module.ToggleCrouching(enabled: boolean?): ()
	isCrouching = if enabled == nil then not isCrouching else enabled

	WalkSpeed.SetModifier("Crouching", if isCrouching then -6 else 0)

	if isCrouching then
		LocalAnimation.TryPlayAnimation(94335137129691, "Crouch")
	else
		LocalAnimation.TryStopAnimation("Crouch")
	end
end

return module