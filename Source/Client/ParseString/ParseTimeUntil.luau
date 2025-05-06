local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToRoundTime = require(ReplicatedStorage.ToRoundTime)
local ParseString = require(script.Parent)

local function getReplacement(timeUntilString: string): string
	local timeUntil = tonumber(timeUntilString) or error("Invalid time until: " .. timeUntilString)
	return ToRoundTime(workspace:GetServerTimeNow(), timeUntil)
end

local function ParseDuration(str: string): string
	return ParseString(str, "TIMEUNTIL", getReplacement)
end

return ParseDuration