local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local ParseString = require(script.Parent)

local function getReplacement(playerName: string): string
	local roleValue = LocalRoundInfo.PlayerRoles()[playerName]
	local role = if roleValue then roleValue() else nil

	local replaceWith = playerName
	if role then
		replaceWith = role:GetFormattedString(playerName)
	end

	return replaceWith
end

local function ParseRoleString(str: string): string
	return ParseString(str, "PLAYER", getReplacement)
end

return ParseRoleString