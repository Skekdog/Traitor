local ProfileManager = require(script.Parent.ProfileManager)

local module = {}

function module.GetKarma(plr: Player): number
	local profile = ProfileManager.GetProfile(plr)
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