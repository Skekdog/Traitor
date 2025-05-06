local Players = game:GetService("Players")
local LocalCharacter = require(script.Parent.LocalCharacter)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)

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

	local roleValue = LocalRoundInfo.PlayerRoles()[Players.LocalPlayer.Name]
	local role = if roleValue then roleValue() else nil
	hum.JumpPower = if role then role.Definition.JumpPower else 18
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