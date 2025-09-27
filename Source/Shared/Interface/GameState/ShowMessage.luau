local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShowMessage = require(ReplicatedStorage.Shared.Interface.Util.ShowMessage)
ReplicatedStorage.Shared:WaitForChild("RoundRule"):WaitForChild("Remotes"):WaitForChild("SendMessage").OnClientEvent:Connect(ShowMessage)

return nil