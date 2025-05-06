return function(start: number, target: number): string
	local diff = math.max(0, math.round(target - start))
	local minutes = diff // 60
	local seconds = diff % 60

	return ("%02d:%02d"):format(minutes, seconds)
end
