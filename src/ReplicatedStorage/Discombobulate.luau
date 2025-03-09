local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function Discombobulate(): ()
    workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Inverse()
end

ReplicatedStorage.ServerClient.Discombobulate.OnClientEvent:Connect(Discombobulate)

return Discombobulate