local ServerScriptService = game:GetService("ServerScriptService")
local ProfileManager = require(ServerScriptService.PlayerData.ProfileManager)
local YieldUntilProfile = require(ServerScriptService.Util.YieldUntilProfile)

local module = {}

function module.GetKarma(plr: Player): number?
	local profile = YieldUntilProfile(plr)
	if not profile then
		return nil
	end
	return if profile then profile.Karma else 1000
end

function module.SetKarma(plr: Player, karma: number): ()
	karma = math.clamp(karma, 1, 1000)

	local profile = ProfileManager.GetProfile(plr)
	if profile then
		profile.Karma = karma
	end

	plr:SetAttribute("Karma", karma)
end

return module