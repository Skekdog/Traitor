local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponsManager = require(script.Parent.Parent.ReplicatedFirst.WeaponsManager)
local Weapons = require(script.Parent.Parent.ReplicatedFirst.WeaponsManager.Weapons)

ReplicatedStorage.ClientServer.FireWeapon.OnServerEvent:Connect(function(plr, cameraRayInfo: Ray?)
    if not cameraRayInfo then
        return
    end

    local char = plr.Character
    if not char then
        return
    end

    char:SetAttribute("Weapon", "Pistol")
    WeaponsManager.Shoot(plr, Weapons[char:GetAttribute("Weapon")], cameraRayInfo)
end)