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

function module.SetScore(plr: Player, score: number, addToTotal: boolean): ()
	local totalScore = module.GetTotalScore(plr)
	if totalScore and addToTotal then
		module.SetTotalScore(plr, totalScore + score)
	end
	plr:SetAttribute("Score", score)
end

function module.AddScore(plr: Player, score: number): ()
	local newScore = module.GetScore(plr) + score
	local totalScore = module.GetTotalScore(plr)
	if totalScore then
		module.SetTotalScore(plr, totalScore + score)
	end
	module.SetScore(plr, newScore, false)
end

return module