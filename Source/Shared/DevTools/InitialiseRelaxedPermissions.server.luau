if workspace:GetAttribute("FirstJoiner") then
	return
end

local Players = game:GetService("Players")

local con: RBXScriptConnection
con = Players.PlayerAdded:Connect(function(player)
	con:Disconnect()
	workspace:SetAttribute("FirstJoiner", player.UserId)
end)