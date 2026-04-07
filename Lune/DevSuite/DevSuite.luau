local stdio = require("@lune/stdio")

export type Options = {[string]: Options | () -> ()}

local function alphabetSort(stringA: string, stringB: string): boolean
	local aIndex = string.byte(stringA)
	local bIndex = string.byte(stringB)

	if aIndex == bIndex then
		return alphabetSort(string.sub(stringA, 2), string.sub(stringB, 2))
	end

	return aIndex < bIndex
end

local function DevSuite(options: Options, back: {Options}): boolean
	local optionNames: {string} = {}
	for option in options do
		local inserted = false
		for index, b in optionNames do
			if alphabetSort(option, b) then
				table.insert(optionNames, index, option)
				inserted = true
				break
			end
		end

		if not inserted then
			table.insert(optionNames, option)
		end
	end

	local backIndex: number?
	if #back > 0 then
		table.insert(optionNames, "- Back")
		backIndex = #optionNames
	end

	table.insert(optionNames, "- Exit")
	local exitIndex = #optionNames

	local index = stdio.prompt("select", `Select an action`, optionNames)
	if index == backIndex then
		local lastOptions = back[#back]
		table.remove(back, #back)
		DevSuite(lastOptions, back)
		return true
	end

	if index == exitIndex then
		return false
	end

	local option = optionNames[index]

	local callOrOptions = options[option]
	if typeof(callOrOptions) == "function" then
		callOrOptions()
		return true
	end

	table.insert(back, options)

	return DevSuite(callOrOptions, back)
end

return DevSuite