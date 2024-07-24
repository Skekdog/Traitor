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

function module.ToRoundTime(time: number, target: number): string
	local diffTime = math.max(math.round(target) - math.round(time), 0)
	local minutes = tostring(diffTime // 60)
	local seconds = tostring(diffTime % 60)

	if string.len(minutes) < 2 then
		minutes = "0"..minutes
	end
	if string.len(seconds) < 2 then
		seconds = "0"..seconds
	end

	return minutes..":"..seconds
end

return module