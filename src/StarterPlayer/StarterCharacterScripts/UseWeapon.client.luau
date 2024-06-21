local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManager = require(script.Parent.Parent.Parent.ReplicatedFirst.InventoryManager)
local ControlManager = require(ReplicatedFirst.ControlManager)

ControlManager.Register("Primary Fire", true, function(action, state, input, toggled)
    while input.UserInputState == Enum.UserInputState.Begin do
        ReplicatedStorage.ClientServer.PrimaryFire:FireServer(workspace.CurrentCamera:ViewportPointToRay(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 1))
        task.wait()
    end
end)

ControlManager.Register("Alternate Fire", true, function(action, state, input, toggled)
    if state ~= Enum.UserInputState.End then
        return
    end
    ReplicatedStorage.ClientServer.AlternateFire:FireServer(workspace.CurrentCamera:ViewportPointToRay(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 1))
end)

ControlManager.Register("Drop", true, function()
    local equipped = InventoryManager.GetEquipped(Players.LocalPlayer)
    if not equipped then
        return
    end
    InventoryManager.Drop(Players.LocalPlayer, equipped, Vector3.zero)
end)