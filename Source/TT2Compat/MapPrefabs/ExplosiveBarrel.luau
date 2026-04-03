local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Combat = require(ReplicatedStorage.API.Combat)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local Types = require(ReplicatedStorage.API.Types)

local function ExplosiveBarrel(prop: Types.Prop, params: Types.DamageParams?): ()
	Combat.MakeExplosion({
		Damage = 200,
		FalloffStart = 3,
		FalloffEnd = 20,
		Pressure = 50000,
		VisualRadius = 20,
		Position = GetPrimaryPart(prop.Model).Position,
		Attacker = params and params.Attacker
	})
end

return ExplosiveBarrel