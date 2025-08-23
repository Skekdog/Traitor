local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)

ReplicatedStorage.Shared.RoundRule.Remotes.PlaySound.OnClientEvent:Connect(function(...)
	PlaySound(...)
end)

return nil