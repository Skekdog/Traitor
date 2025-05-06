local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShowMessage = require(ReplicatedStorage.ShowMessage)
ReplicatedStorage:WaitForChild("RoundRule"):WaitForChild("Remotes"):WaitForChild("SendMessage").OnClientEvent:Connect(ShowMessage)