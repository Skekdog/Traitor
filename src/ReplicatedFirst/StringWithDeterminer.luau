local vowels = {"a", "e", "i", "o", "u"}

return function(str: string): string
	local lowered = str:lower()

	local determiner = "a "
	if table.find(vowels, lowered:sub(1)) then
		determiner = "an "
	end

	return determiner..str
end