local Players = game:GetService("Players")

local function onPlayerAdded(player: Player): ()
	local role = player:GetRoleInGroup(game.CreatorId)
	if role ~= "Guest" then
		player:SetAttribute("ChatTag", role)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

return nil