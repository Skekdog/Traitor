local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local ParseString = require(script.Parent)

local function getReplacement(playerName: string): string
	local role = LocalParticipantInfo.GetParticipant(playerName).Role()
	local replaceWith = role:FormatString(playerName)

	return replaceWith
end

local function ParseRoleString(str: string): string
	return ParseString(str, "PLAYER", getReplacement)
end

return ParseRoleString