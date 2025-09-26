local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local function GetAliveRoles(round: Types.Round, roles: {string}): {Types.Participant}
	local alive: {Types.Participant} = {}

	for _, roleName in roles do
		local role = round:GetRoleFromRoleName(roleName)
		for _, participant in round:GetParticipantsWithRole(role) do
			if participant:IsAlive() then
				table.insert(alive, participant)
			end
		end
	end

	return alive
end

return GetAliveRoles