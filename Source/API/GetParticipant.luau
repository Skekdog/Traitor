local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetMapObjectWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapObjectWithTag)
local GetRound = require(script.Parent.GetRound)
local Types = require(ReplicatedStorage.API.Types)

local function GetParticipant(identifier: Instance | string): Types.Participant?
	local finalIdentifier: string?
	if typeof(identifier) == "string" then
		finalIdentifier = identifier
	elseif identifier:IsA("Player") then
		finalIdentifier = identifier.Name
	else
		if not identifier:IsDescendantOf(workspace) then
			return nil
		end

		local char = GetMapObjectWithTag(identifier, "Character")
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