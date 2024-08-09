-- return function(time: number, target: number): string
-- 	local diffTime = math.max(0, math.round(target - time))
-- 	local minutes = tostring(diffTime // 60)
-- 	local seconds = tostring(diffTime % 60)

-- 	if string.len(minutes) < 2 then
-- 		minutes = "0"..minutes
-- 	end
-- 	if string.len(seconds) < 2 then
-- 		seconds = "0"..seconds
-- 	end

-- 	return minutes..":"..seconds
-- end

-- todo: finish this
return function(start: number, target: number): string
	local diff = math.max(0, math.round(target - start))
	local minutes = diff // 60
	local seconds = diff % 60

	return ("%d:%d"):format(minutes, seconds)
end
