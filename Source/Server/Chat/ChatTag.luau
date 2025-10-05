local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local role = player:GetRoleInGroup(game.CreatorId)
	print(role)
	if role ~= "Guest" then
		player:SetAttribute("ChatTag", role)
	end
end)

return nil