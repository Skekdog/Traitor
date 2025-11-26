local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local GetRound = require(script.Parent.GetRound)
local Combat = require(ServerScriptService.Combat.Combat)

local module = {}

function module.MakeExplosion(params: {
	Position: Vector3,
	Damage: number,
	FalloffBegin: number?,
	FalloffEnd: number,
	Attacker: Types.Participant?,
	IgnoreKarma: boolean?,
}, sound: Sound?): ()
	Combat.CreateExplosion(GetRound(), ExplosionParams.new({
		Damage = params.Damage,
		FalloffBegin = params.FalloffBegin or 0,
		FalloffEnd = params.FalloffEnd,
		Pressure = params.Damage * 50,
		VisualRadius = params.FalloffEnd,
		IgnoreKarma = params.IgnoreKarma,
		IgnoreScore = params.IgnoreKarma,
		IgnoreSelfDefense = params.IgnoreKarma,
	}, params.Position, params.Attacker), nil, sound)
end

return module