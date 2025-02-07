local Players = game:GetService("Players")
local module = {}

local modifiers: {[string]: number} = {}

local function updateWalkSpeed(): ()
	local char = Players.LocalPlayer.Character
	if not char then
		return
	end

	local hum = char:WaitForChild("Humanoid")
	assert(hum:IsA("Humanoid"), "Humanoid is not a Humanoid")

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