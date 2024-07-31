local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManager = require(script.Parent.InventoryManager)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Viewmodel = require(script.Parent.Viewmodel)

return function(): ()
    local equipped = InventoryManager.GetEquipped(Players.LocalPlayer)
    if not equipped or equipped.Kind ~= "Gun" then
        return
    end

    local max = equipped.Base.MagazineSize or InventoryManager.AmmoData[equipped.Base.AmmoType :: any].Max
    if LocalRoundInfo.Ammo and LocalRoundInfo.Ammo < max then
        Viewmodel.ReloadSpring.p = Vector3.new(10, 5, 10)
        ReplicatedStorage.ClientServer.ReloadWeapon:FireServer()
    end
end
