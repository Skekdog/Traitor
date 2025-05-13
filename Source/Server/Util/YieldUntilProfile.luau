local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ProfileManager = require(ServerScriptService.PlayerData.ProfileManager)

local function YieldUntilProfile(plr: Player): ProfileManager.PlayerData?
	local profile: ProfileManager.PlayerData?

	while not profile and plr:IsDescendantOf(Players) do
		profile = ProfileManager.GetProfile(plr)
		task.wait()
	end

	return profile
end

return YieldUntilProfile