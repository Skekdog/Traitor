local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlManager = require(ReplicatedFirst.ControlManager)

ControlManager.Register("Primary Fire", true, function(action, state)
    if state ~= Enum.UserInputState.End then
        return
    end
    ReplicatedStorage.ClientServer.FireWeapon:FireServer(workspace.CurrentCamera:ViewportPointToRay(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 1))
end)
