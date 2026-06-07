local BadgeService = game:GetService("BadgeService")

local Badge = {}

function Badge.Award(badgeId: number, player: Player): ()
	if Badge.IsOwned(badgeId, player) then
		return
	end

	local tries = 0
	local success = false
	repeat
		success = pcall(function()
			BadgeService:AwardBadgeAsync(player.UserId, badgeId)
		end)
		task.wait(1)
	until success or tries > 3
end

function Badge.IsOwned(badgeId: number, player: Player): boolean
	local tries = 0
	local success, result: boolean | string = false, false -- string if errors
	repeat
		success, result = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
		end)
		task.wait(1)
	until success or tries > 3

	return if typeof(result) == "string" then false else result
end

return table.freeze(Badge)