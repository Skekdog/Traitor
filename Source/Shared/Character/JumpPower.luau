local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)
local LocalCharacter = require(script.Parent.LocalCharacter)

local modifiers: {[string]: boolean} = {}

local module = {}

local function setJumpPower(): ()
	local hum = LocalCharacter.Humanoid()
	if not hum then
		return
	end

	for _, v in modifiers do
		if not v then
			hum.JumpPower = 0
			return
		end
	end

	hum.JumpPower = LocalRoundInfo.GetPlayerRole().Definition.JumpPower or Defaults.JumpPower
end

function module.SetModifier(modifier: string, canJump: boolean): ()
	modifiers[modifier] = canJump
	setJumpPower()
end

function module.Reset()
	modifiers = {}
	setJumpPower()
end

return module