local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileManager = require(script.Parent.ProfileManager)

ReplicatedStorage.ClientServer.GetKarma.OnServerInvoke = function(plr, target)
	local profile = ProfileManager.GetProfile(plr)
	return profile and profile.Karma or 1000
end