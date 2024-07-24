local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRound = require(script.Parent.GetRound)
local InventoryManager = require(ReplicatedFirst.InventoryManager)
local ItemTypes = require(ReplicatedFirst.ItemTypes)
local Types = require(ReplicatedFirst.RoundHandler.Types)
local WeaponsManager = require(script.Parent.WeaponsManager)

local function allow(plr: Player, cameraRayInfo: unknown, requireRayInfo: boolean?): (ItemTypes.Item? | ItemTypes.Weapon, Types.Participant?)
    if not cameraRayInfo and requireRayInfo then
        return
    end

    if requireRayInfo and typeof(cameraRayInfo) ~= "Ray" then
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

    local round = GetRound()
    if not round then
        return
    end
    return weapon, round:GetParticipant(plr.Name)
end

ReplicatedStorage.ClientServer.PrimaryFire.OnServerInvoke = function(plr, cameraRayInfo: unknown)
    local weapon, participant = allow(plr, cameraRayInfo, true)
    if not weapon or not participant then
        return
    end
    assert(typeof(cameraRayInfo) == "Ray")

    if weapon.Kind == "Item" then
        assert(weapon.Base.PrimaryFire)
        weapon.Base.PrimaryFire(participant, cameraRayInfo)
    else
        return WeaponsManager.Shoot(plr, weapon, cameraRayInfo)
    end
end

ReplicatedStorage.ClientServer.AlternateFire.OnServerEvent:Connect(function(plr, cameraRayInfo: unknown)
    local weapon, participant = allow(plr, cameraRayInfo, true)
    if not weapon or not participant then
        return
    end
    assert(typeof(cameraRayInfo) == "Ray")

    if weapon.Base.Kind == "Item" and weapon.Base.AlternateFire then
        weapon.Base.AlternateFire(participant, cameraRayInfo)
    end
end)

ReplicatedStorage.ClientServer.AimWeapon.OnServerEvent:Connect(function(plr, isAiming: unknown)
    local weapon, participant = allow(plr)
    if not weapon or not participant then
        return
    end
    if typeof(isAiming) ~= "boolean" then
        return
    end

    InventoryManager.SetAiming(plr, isAiming)
end)

ReplicatedStorage.ClientServer.ReloadWeapon.OnServerEvent:Connect(function(plr)
    local weapon, participant = allow(plr)
    if not weapon or not participant or weapon.Kind ~= "Gun" then
        return
    end

    InventoryManager.Reload(plr, weapon)
end)

ReplicatedStorage.ClientServer.DropAmmo.OnServerEvent:Connect(function(plr)
    local weapon, participant = allow(plr)
    if not weapon or not participant or weapon.Kind ~= "Gun" then
        return
    end

    InventoryManager.DropAmmo(plr, weapon)
end)