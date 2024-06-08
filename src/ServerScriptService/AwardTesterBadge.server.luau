local BS = game:GetService("BadgeService")
local Players = game:GetService("Players")

local _earlyTesters = { -- These players should be awarded the badge whenever they join, even after release
	465187670,
	16481979,
	2356511943,
	315415902,
	305546034,
	2021782328,
	157359649,
	435767054,
	120380298,
	1939149799,
	879872945,
	1217524874,
	1914198146,
	507682950,
	706326447,
	629091420,
	519873663,
	19990629,
	4132746558,
	3541273531,
	4051361442,
	3106058458
}

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