local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)
local LocalCharacter = require(script.Parent.LocalCharacter)
local module = {}

local modifiers: {[string]: number} = {}

local function updateWalkSpeed(): ()
	local hum = LocalCharacter.Humanoid()
	if not hum then
		return
	end

	local role = LocalRoundInfo.GetPlayerRole()
	local speed = role.Definition.WalkSpeed or Defaults.WalkSpeed
	
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