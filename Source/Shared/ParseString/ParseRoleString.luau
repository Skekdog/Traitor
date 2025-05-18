local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local ParseString = require(script.Parent)

local function getReplacement(playerName: string): string
	local role = LocalRoundInfo.GetPlayerRole(playerName)
	local replaceWith = role:GetFormattedString(playerName)

	return replaceWith
end

local function ParseRoleString(str: string): string
	return ParseString(str, "PLAYER", getReplacement)
end

return ParseRoleString