local Players = game:GetService("Players")

local function destroyFootsteps(char: Model): ()
	char:WaitForChild("HumanoidRootPart"):WaitForChild("Running"):Destroy()
end

local function removeFootsteps(player: Player): ()
	local char = player.Character
	if char then
		destroyFootsteps(char)
	end

	player.CharacterAdded:Connect(function(char: Model)
    	destroyFootsteps(char)
    end)
end

Players.PlayerAdded:Connect(removeFootsteps)

for _, player in Players:GetPlayers() do
	if player == Players.LocalPlayer then
		continue
	end

    removeFootsteps(player)
end

return nil