local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage.ClientServer.GetKarma.OnServerInvoke = function(plr, target)
	local profile = (script :: any).Parent.PlayerSetup.GetProfile:Invoke(target)
	return profile and profile.Karma or nil
end