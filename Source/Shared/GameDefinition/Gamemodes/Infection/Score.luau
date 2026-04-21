local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
local Infected = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.Infection.Roles.Infected)
local Survivor = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.Infection.Roles.Survivor)

local Score = {}

function Score.Kill(attacker: Types.Participant, victim: Types.Participant): ()
	if attacker == victim then
		attacker:AddScore("Suicide", -2)
        return
    end

	local attackerRole = attacker:GetRole().Definition
	local victimRole = victim:GetRole().Definition

	if attackerRole == Infected and victimRole == Survivor then
		attacker:AddScore("Infected Survivor", 1)
	elseif attackerRole == Survivor and victimRole == Infected then
		attacker:AddScore("Killed Infected", 0.25)
	end
end

function Score.Finish(round: Types.Round): ()
	local initialInfected: Types.Participant? = round.Extras.InitialInfected

	local survivors = round:GetParticipantsWithRole(round:GetRoleFromRoleName("Survivor"))
	for _, survivor in survivors do
		survivor:AddScore("Surviving", #survivors * 1.5)
	end

	local infectedRole = round:GetRoleFromRoleName("Infected")

	assert(round.VictoryData)
	if not initialInfected or round.VictoryData.Victor ~= infectedRole then
		return
	end

	local infected = #round:GetParticipantsWithRole(infectedRole)
	initialInfected:AddScore("Infected Players", infected)
end

return Score