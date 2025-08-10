local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage.Remotes.ClientServer.Crouch.OnServerEvent:Connect(function(plr, isCrouching: unknown): ()
	if typeof(isCrouching) ~= "boolean" then
		return
	end

	local char = plr.Character
	if not char then
		return
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end

	hum:SetAttribute("IsCrouching", isCrouching)
end)

return nil