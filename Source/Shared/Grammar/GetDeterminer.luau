local vowels = {"a", "e", "i", "o", "u"}

local function GetDeterminer(str: string): string
	local lowered = str:lower()

	local determiner = "a"
	if table.find(vowels, lowered:sub(1, 1)) then
		determiner = "an"
	end

	return determiner
end

return GetDeterminer