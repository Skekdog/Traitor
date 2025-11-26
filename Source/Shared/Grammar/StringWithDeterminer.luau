local vowels = {"a", "e", "i", "o", "u"}
local vowelSequences = {"hou", "hon", "hei"}

return function(str: string): string
	local lowered = str:lower()

	local determiner = "a "
	if table.find(vowels, lowered:sub(1, 1)) or table.find(vowelSequences, lowered:sub(1, 3)) then
		determiner = "an "
	end

	return determiner..str
end