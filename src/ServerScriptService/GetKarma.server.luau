local ReplicatedStorage = game:GetService("ReplicatedStorage")
local isFirstTime = true
ReplicatedStorage.ClientServer.GetKarma.OnServerInvoke = function(plr, target)
	if isFirstTime then
		task.wait(1)
		isFirstTime = false
	end
	local profile = script.Parent.PlayerSetup.GetProfile:Invoke(target)
	return profile and profile.Karma or nil
end