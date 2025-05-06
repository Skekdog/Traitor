
local function ParseString(str: string, identifier: string, replace: (parameter: string) -> string): string
	while true do
		local start1, finish1 = str:find(`[{identifier}-`, 1, true)
		if not start1 or not finish1 then
			break
		end

		local start2, finish2 = str:find("]", finish1 + 1, true)
		if not start2 or not finish2 then
			error("Missing closing bracket for parse string: " .. str)
		end

		local parameter = str:sub(finish1 + 1, start2 - 1)
		assert(parameter ~= "", "Missing parameter for parse string: " .. str)

		local replaceWith = replace(parameter)

		local toReplace = str:sub(start1, finish2)
		toReplace = toReplace:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]","%%%1" :: "%%%1")
		str = str:gsub(toReplace, replaceWith)
	end

	return str
end

return ParseString
