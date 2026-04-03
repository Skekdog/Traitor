local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Message = require(ReplicatedStorage.API.Interface.Message)

local JOIN_COLOR = Color3.fromRGB(100, 207, 100)
local LEAVE_COLOR = Color3.fromRGB(255, 213, 98)

local function onPlayerAdded(player: Player): ()
	Message.Chat(`<font color='#{JOIN_COLOR:ToHex()}'>` .. player.Name .. " has joined the server.</font>", "All")
end

Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player: Player): ()
	Message.Chat(`<font color='#{LEAVE_COLOR:ToHex()}'>` .. player.Name .. " has left the server.</font>", "All")
end)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

return nil