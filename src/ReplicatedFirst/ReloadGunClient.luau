local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmmoData = require(script.Parent.AmmoData)
local InventoryManager = require(script.Parent.InventoryManagerClient)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Viewmodel = require(script.Parent.Viewmodel)

return function(): ()
    local equipped = InventoryManager.Equipped
    if not equipped or equipped.Kind ~= "Gun" then
        return
    end

    local max = equipped.Base.MagazineSize or AmmoData[equipped.Base.AmmoType :: any].Max
    if LocalRoundInfo.Ammo and LocalRoundInfo.Ammo < max then
        Viewmodel.ReloadSpring.p = Vector3.new(10, 5, 10)
        ReplicatedStorage.ClientServer.ReloadWeapon:FireServer()
    end
end
