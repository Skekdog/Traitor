local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManager = require(script.Parent.Parent.ReplicatedFirst.InventoryManager)
local ItemTypes = require(script.Parent.Parent.ReplicatedFirst.ItemsManager.ItemTypes)
local WeaponsManager = require(script.Parent.WeaponsManager)

ReplicatedStorage.ClientServer.PrimaryFire.OnServerEvent:Connect(function(plr, cameraRayInfo: Ray?)
    if not cameraRayInfo then
        return
    end

    local char = plr.Character
    if not char then
        return
    end

    local weapon = InventoryManager.GetEquipped(plr) :: ItemTypes.Item | ItemTypes.Weapon
    if not weapon then
        return
    end

    if weapon.Base.Kind == "Item" then
        assert(weapon.Base.PrimaryFire)
        weapon.Base.PrimaryFire()
    else
        WeaponsManager.Shoot(plr, weapon :: ItemTypes.Weapon, cameraRayInfo)
    end
end)