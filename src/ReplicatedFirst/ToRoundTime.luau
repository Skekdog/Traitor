return function(time: number, target: number): string
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