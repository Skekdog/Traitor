local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetMapThingWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapThingWithTag)
local GetRound = require(script.Parent.GetRound)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function GetParticipant(identifier: Instance | string): Types.Participant?
	local finalIdentifier
	if typeof(identifier) == "Instance" then
		local char = GetMapThingWithTag(identifier, "Character")
		finalIdentifier = char
	end

	if typeof(finalIdentifier) ~= "string" or not finalIdentifier:IsA("Model") or not finalIdentifier:IsA("BasePart") then
		return nil
	end

	return GetRound():GetParticipant(finalIdentifier)
end

return GetParticipant