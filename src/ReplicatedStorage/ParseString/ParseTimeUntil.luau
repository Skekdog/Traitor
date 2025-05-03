local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(ReplicatedStorage.LocalRoundInfo)
local ToRoundTime = require(ReplicatedStorage.ToRoundTime)
local ParseString = require(script.Parent)

local function getReplacement(timeUntilString: string): string
	local timeUntil = tonumber(timeUntilString) or error("Invalid time until: " .. timeUntilString)
	return ToRoundTime(LocalRoundInfo.StartTime() or 0, timeUntil)
end

local function ParseDuration(str: string): string
	return ParseString(str, "TIMEUNTIL", getReplacement)
end

return ParseDuration