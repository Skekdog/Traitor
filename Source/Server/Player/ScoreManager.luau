local ServerScriptService = game:GetService("ServerScriptService")
local ProfileManager = require(ServerScriptService.PlayerData.ProfileManager)
local YieldUntilProfile = require(ServerScriptService.Util.YieldUntilProfile)

local module = {}

function module.GetTotalScore(plr: Player): number?
	local profile = YieldUntilProfile(plr)
	if not profile then
		return nil
	end
	return profile.TotalPoints
end

function module.SetTotalScore(plr: Player, totalScore: number): ()
	local profile = ProfileManager.GetProfile(plr)
	if profile then
		profile.TotalPoints = totalScore
	end
	plr:SetAttribute("TotalScore", totalScore)
end

function module.GetScore(plr: Player): number
	return plr:GetAttribute("Score") :: number? or 0
end

function module.SetScore(plr: Player, score: number): ()
	plr:SetAttribute("Score", score)
end

function module.AddScore(plr: Player, score: number): ()
	local newScore = module.GetScore(plr) + score
	module.SetScore(plr, newScore)
end

return module