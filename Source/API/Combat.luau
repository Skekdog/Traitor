local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Server = require(ReplicatedStorage.API.Item.Behaviour.Server)
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local GetRound = require(script.Parent.GetRound)

local module = {}

function module.MakeExplosion(params: {
	Position: Vector3,
	Damage: number,
	FalloffStart: number?,
	FalloffEnd: number,
	Attacker: Types.Participant?,
	IgnoreKarma: boolean?,
	Pressure: number?,
	VisualRadius: number?,
	BeforeHitParticipant: Types.BeforeHitParticipantExplosionInfo?,
	FilterImpulse: ((Types.ExplosionInfo, participant: Types.Participant) -> boolean?)?
}, sound: Sound?): ()
	Server.CreateExplosion(GetRound(), ExplosionParams.new({
		Damage = params.Damage,
		FalloffStart = params.FalloffStart or 0,
		FalloffEnd = params.FalloffEnd,
		Pressure = params.Pressure or params.Damage * 50,
		VisualRadius = params.VisualRadius or params.FalloffEnd,
		IgnoreKarma = params.IgnoreKarma,
		IgnoreScore = params.IgnoreKarma,
		IgnoreSelfDefense = params.IgnoreKarma,
		BeforeHitParticipant = params.BeforeHitParticipant,
		FilterImpulse = params.FilterImpulse,
	}, params.Position, params.Attacker), sound)
end

return module