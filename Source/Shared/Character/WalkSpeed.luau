local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)
local LocalCharacter = require(script.Parent.LocalCharacter)
local module = {}

local participant = LocalParticipantInfo.GetParticipant()

local modifiers: {[string]: number} = {}

local function updateWalkSpeed(): ()
	local hum = LocalCharacter.Humanoid()
	if not hum then
		return
	end

	local role = participant.Role()
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

function module.GetModifier(modifier: string): number
	return modifiers[modifier] or 0
end

return table.freeze(module)