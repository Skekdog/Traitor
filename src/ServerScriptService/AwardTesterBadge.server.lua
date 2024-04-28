local BS = game:GetService("BadgeService")
local Players = game:GetService("Players")
Players.PlayerAdded:Connect(function(plr)
	local tries = 0
	local suc = false
	repeat
		suc = pcall(function()
			BS:AwardBadge(plr.UserId, 2136698808)
		end)
		task.wait(1)
	until suc or tries > 3
end)