local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local LocalCharacter = require(script.Parent.LocalCharacter)
local module = {}

local modifiers: {[string]: number} = {}

local function updateWalkSpeed(): ()
	local hum = LocalCharacter.Humanoid()
	if not hum then
		return
	end

	local roleValue = LocalRoundInfo.PlayerRoles()[Players.LocalPlayer.Name]
	local role = if roleValue then roleValue() else nil
	local speed = if role then role.Definition.WalkSpeed or 16 else 16
	
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