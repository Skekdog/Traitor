local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaySound = require(ReplicatedStorage.API.PlaySound)

ReplicatedStorage.Shared.RoundRule.Remotes.PlaySound.OnClientEvent:Connect(function(...)
	PlaySound(...)
end)

return nil