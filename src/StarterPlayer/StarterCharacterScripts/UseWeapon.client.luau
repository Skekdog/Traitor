local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlManager = require(ReplicatedFirst.ControlManager)

ControlManager.Register("Primary Fire", true, function()
    ReplicatedStorage.ClientServer.FireWeapon:FireServer(workspace.CurrentCamera:ViewportPointToRay(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 1))
end)
