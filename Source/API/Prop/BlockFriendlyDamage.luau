local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsHostileParticipant = require(script.Parent.IsHostileParticipant)
local Types = require(ReplicatedStorage.API.Types)

local function BlockFriendlyDamage(prop: Types.Prop, params: Types.DamageParams): boolean
	local attacker = params.Attacker
	if not attacker then
		return true
	end

	return IsHostileParticipant(prop, attacker)
end

return BlockFriendlyDamage