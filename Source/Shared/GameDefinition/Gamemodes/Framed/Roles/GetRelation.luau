local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Targets = require(script.Parent.Parent.GameState.Targets)
local Types = require(ReplicatedStorage.API.Types)

export type Relation = "Target" | "Hunter" | "RDM" | "Police" | "Undercover"

local function GetRelation(attacker: Types.Participant, target: Types.Participant): Relation
	local relation: Relation = "RDM"
	if target:GetRole().Definition.Name == "Police" and attacker:GetRole().Definition.Name == "Framed" then
		relation = "Police"
	elseif target:GetRole().Definition.Name == "Undercover" and attacker:GetRole().Definition.Name == "Framed" then
		relation = "Undercover"
	elseif Targets.GetHunter(attacker) == target then
		relation = "Hunter"
	elseif Targets.GetTarget(attacker) == target then
		relation = "Target"
	end
	return relation
end

return GetRelation