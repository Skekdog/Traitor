local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(script.Parent.Types)
local _DamageSource = require(ReplicatedStorage.Shared.RoundRule.DamageSource)

local DamageSource = {}

function DamageSource.IsPassive(source: Types.DamageSource): boolean
	return _DamageSource.IsPassive(source)
end

function DamageSource.IsFirearm(source: Types.DamageSource): boolean
	return _DamageSource.IsFirearm(source)
end

function DamageSource.IsMelee(source: Types.DamageSource): boolean
	return _DamageSource.IsMelee(source)
end

return DamageSource