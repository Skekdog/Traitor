local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManager = require(script.Parent.Parent.Parent.ReplicatedFirst.InventoryManager)
local ControlManager = require(ReplicatedFirst.ControlManager)

ControlManager.Register("Primary Fire", true, function(action, state)
    if state ~= Enum.UserInputState.End then
        return
    end
    ReplicatedStorage.ClientServer.FireWeapon:FireServer(workspace.CurrentCamera:ViewportPointToRay(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 1))
end)

ControlManager.Register("Drop", true, function()
    local equipped = InventoryManager.GetEquipped(Players.LocalPlayer)
    if not equipped then
        return
    end
    InventoryManager.Drop(Players.LocalPlayer, equipped, Vector3.zero)
end)