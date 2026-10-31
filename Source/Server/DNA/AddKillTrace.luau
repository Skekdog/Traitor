local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DNATraces = require(ReplicatedStorage.API.DNATraces)
local DamageSource = require(ReplicatedStorage.API.DamageSource)
local GameHooks = require(ReplicatedStorage.API.GameHooks)
local Types = require(ReplicatedStorage.API.Types)

local MAX_KILL_DISTANCE = 60
local MAX_KILL_TRACE_DURATION = 120

GameHooks.OnDeath["DNATraces"] = function(round: Types.Round, participant: Types.Participant): ()
	local corpse = participant.Corpse
	if not corpse then
		return
	end

	local attacker = corpse.Killer
	if not attacker then
		return
	end

	if (attacker:HasSelfDefenseAgainstParticipant(participant) and not participant:GetRole().Definition.CorpseHidesSelfDefense) or participant:IsFreeKill(attacker) then
		return
	end

	local char = corpse.Model
	if not char then
		return
	end

	local isEligible = DamageSource.IsFirearm(corpse.CorpseView.DamageSource) or DamageSource.IsMelee(corpse.CorpseView.DamageSource)
	if not isEligible then
		return
	end

	local distance = attacker.Player:DistanceFromCharacter(char:GetPivot().Position)
	if distance == 0 then
		return
	end

	local duration = math.lerp(MAX_KILL_TRACE_DURATION, 0, distance / MAX_KILL_DISTANCE)
	DNATraces.Add(participant, attacker, duration, Content.fromAssetId(1043921089), char)

	participant:AddCorpseIcon({
		Name = "DNATrace",
		Icon = Content.fromAssetId(135886260297010),
		Description = "Traces of the killer's DNA are on the body. Use a DNA Scanner to track them.",
		DisplayText = `[TIMEUNTIL-{tostring(workspace:GetServerTimeNow() + duration)}]`,
	})
end

return nil