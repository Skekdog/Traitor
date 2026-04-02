local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local function IsHostileParticipant(prop: Types.Prop, participant: Types.Participant): boolean
	local planter: Types.Participant = prop.Extras.Participant
	if not planter then
		return true
	end

	return not participant:IsAlliedWithParticipant(planter)
end

return IsHostileParticipant