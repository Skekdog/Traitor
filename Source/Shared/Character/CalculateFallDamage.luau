local MIN_VELOCITY = 40
local SCALE = 0.1

local MIN_DAMAGE = 0.5

local function CalculateFallDamage(velocity: number): number
	if velocity <= MIN_VELOCITY then
		return 0
	end

	local damage = SCALE * (velocity - MIN_VELOCITY) ^ 2
	return if damage >= MIN_DAMAGE then damage else 0
end

return CalculateFallDamage