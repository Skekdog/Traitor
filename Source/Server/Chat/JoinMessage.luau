local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Notification = require(ReplicatedStorage.API.Notification)

local JOIN_COLOR = Color3.fromRGB(100, 207, 100)
local LEAVE_COLOR = Color3.fromRGB(255, 213, 98)

local function onPlayerAdded(player: Player): ()
	Notification(`<font color='#{JOIN_COLOR:ToHex()}'>` .. player.Name .. " has joined the server.</font>", "Chat")
end

Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player: Player): ()
	Notification(`<font color='#{LEAVE_COLOR:ToHex()}'>` .. player.Name .. " has left the server.</font>", "Chat")
end)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

return nil