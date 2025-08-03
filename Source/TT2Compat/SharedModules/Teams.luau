local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Participant = require(ReplicatedStorage.Shared.RoundRule.Participant)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local Teams = {}

local originalSetRole = Participant.SetRole
Participant.SetRole = function(participant: Types.Participant, role: Types.RoleDefinition?)
	Teams[participant.Player] = if role then role.Name else nil
	originalSetRole(participant, role)
end

return Teams