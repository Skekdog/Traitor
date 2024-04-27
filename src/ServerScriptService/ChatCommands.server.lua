local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
Players.PlayerAdded:Connect(function(plr)
	plr.Chatted:Connect(function(msg, rec)
		if rec then return end
		msg = msg:lower()
		if msg == "!settings" then
			ReplicatedStorage.ServerClient.OpenSettings:FireClient(plr)
		end
	end)
end)