local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetMapThingWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapThingWithTag)
local GetRound = require(script.Parent.GetRound)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function GetParticipant(identifier: Instance | string): Types.Participant?
	local finalIdentifier: string?
	if typeof(identifier) == "string" then
		finalIdentifier = identifier
	else
		local char = GetMapThingWithTag(identifier, "Character")
		if char then
			finalIdentifier = char.Name
		end
	end

	if not finalIdentifier then
		return nil
	end

	return GetRound():GetParticipant(finalIdentifier)
end

return GetParticipant