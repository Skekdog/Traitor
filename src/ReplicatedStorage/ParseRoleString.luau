local LocalRoundInfo = require(script.Parent.LocalRoundInfo)

local function ParseRoleString(str: string): string
	while true do
		local start1, finish1 = str:find("[PLAYER-", 1, true)
		if not start1 or not finish1 then
			break
		end

		local start2, finish2 = str:find("]", finish1 + 1, true)
		if not start2 or not finish2 then
			error("Missing closing bracket for role string: " .. str)
		end

		local playerName = str:sub(finish1 + 1, start2 - 1)
		assert(playerName ~= "", "Missing player name for role string: " .. str)

		local roleValue = LocalRoundInfo.PlayerRoles()[playerName]
		local role = if roleValue then roleValue() else nil

		local replaceWith = playerName
		if role then
			replaceWith = role:GetFormattedString(playerName)
		end

		local toReplace = str:sub(start1, finish2)
		toReplace = toReplace:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]","%%%1" :: "%%%1")
		str = str:gsub(toReplace, replaceWith)
	end

	return str
end

return ParseRoleString