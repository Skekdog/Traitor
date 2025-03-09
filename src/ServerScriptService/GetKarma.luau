local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileManager = require(script.Parent.ProfileManager)

local function GetKarma(plr: Player): number
	local profile = ProfileManager.GetProfile(plr)
	return if profile then profile.Karma else 1000
end

ReplicatedStorage.ClientServer.GetKarma.OnServerInvoke = function(plr, target: unknown): number?
	if typeof(target) ~= "Instance" or not target:IsA("Player") then
		return nil
	end

	return GetKarma(target)
end

return GetKarma