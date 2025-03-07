local LocalCharacter = require(script.Parent.LocalCharacter)
local module = {}

local modifiers: {[string]: number} = {}

local function updateWalkSpeed(): ()
	local hum = LocalCharacter.GetHumanoid()
	if not hum then
		return
	end

	local speed = 16
	for _, v in modifiers do
		speed += v
	end

	hum.WalkSpeed = speed
end

function module.Reset(): ()
	modifiers = {}
	updateWalkSpeed()
end

function module.SetModifier(modifier: string, value: number): ()
	modifiers[modifier] = value
	updateWalkSpeed()
end

return module