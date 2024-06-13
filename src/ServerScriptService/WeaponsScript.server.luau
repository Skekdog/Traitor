local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManager = require(script.Parent.Parent.ReplicatedFirst.InventoryManager)
local WeaponsManager = require(script.Parent.Parent.ReplicatedFirst.WeaponsManager)
local Weapons = require(script.Parent.Parent.ReplicatedFirst.WeaponsManager.Weapons)

ReplicatedStorage.ClientServer.AimWeapon.OnServerEvent:Connect(function(plr, isAiming)
    local char = plr.Character :: any
    char:SetAttribute("Weapon", isAiming)
end)

ReplicatedStorage.ClientServer.FireWeapon.OnServerEvent:Connect(function(plr, cameraRayInfo: Ray?)
    if not cameraRayInfo then
        return
    end

    local char = plr.Character
    if not char then
        return
    end

    local weapon = InventoryManager.GetEquipped(plr)
    if not weapon then
        return
    end
    WeaponsManager.Shoot(plr, Weapons[weapon.Name], cameraRayInfo)
end)