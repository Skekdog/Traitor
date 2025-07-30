local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Combat = require(ServerScriptService.Combat.Combat)
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function ExplosiveBarrel(prop: Types.MapProp, params: Types.DamageParams?): ()
	local explosionParams = ExplosionParams.new({
		Damage = 200,
		FalloffBegin = 3,
		FalloffEnd = 20,
		Pressure = 50000,
		VisualRadius = 20,
	}, prop.Model.Position, if params then params.Attacker else nil)
	Combat.CreateExplosion(prop.Round, explosionParams)
end

return ExplosiveBarrel