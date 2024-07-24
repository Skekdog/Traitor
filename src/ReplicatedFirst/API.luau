local module = {}

function module.LerpNumber(num1: number, num2: number, decimal: number): number --Linearly interpolates a number
	return num1 + ((num2 - num1) * decimal)
end

local vowels = {"a", "e", "i", "o", "u"}
function module.StringWithDeterminer(str: string): string
	local lowered = str:lower()

	local determiner = "a "
	if table.find(vowels, lowered:sub(1)) then
		determiner = "an "
	end

	return determiner..str
end

return module