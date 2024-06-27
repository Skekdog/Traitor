local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local InventoryManager = require(script.Parent.Parent.ReplicatedFirst.InventoryManager)
local ItemTypes = require(script.Parent.Parent.ReplicatedFirst.ItemsManager.ItemTypes)
local RoundHandler = require(script.Parent.Parent.ReplicatedFirst.RoundHandler.RoundHandler)
local Types = require(script.Parent.Parent.ReplicatedFirst.RoundHandler.Types)
local WeaponsManager = require(script.Parent.WeaponsManager)

local function allow(plr: Player, cameraRayInfo: Ray?, requireRayInfo: boolean?): (ItemTypes.Item?, Types.Participant?)
    if not cameraRayInfo and requireRayInfo then
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

    local roundId = ServerStorage:GetAttribute("RoundID")
    if not roundId then
        return
    end

    local round = RoundHandler.GetRound(roundId)
    return weapon, round:GetParticipant(plr.Name)
end

ReplicatedStorage.ClientServer.PrimaryFire.OnServerEvent:Connect(function(plr, cameraRayInfo: Ray?)
    local weapon, participant = allow(plr, cameraRayInfo, true)
    if not weapon or not participant then
        return
    end
    assert(cameraRayInfo)

    if weapon.Base.Kind == "Item" then
        assert(weapon.Base.PrimaryFire)
        weapon.Base.PrimaryFire(participant, cameraRayInfo)
    else
        print(weapon)
        WeaponsManager.Shoot(plr, weapon :: ItemTypes.Weapon, cameraRayInfo)
    end
end)

ReplicatedStorage.ClientServer.AlternateFire.OnServerEvent:Connect(function(plr, cameraRayInfo: Ray?)
    local weapon, participant = allow(plr, cameraRayInfo, true)
    if not weapon or not participant then
        return
    end
    assert(cameraRayInfo)

    if weapon.Base.Kind == "Item" and weapon.Base.AlternateFire then
        weapon.Base.AlternateFire(participant, cameraRayInfo)
    end
end)

ReplicatedStorage.ClientServer.ReloadWeapon.OnServerEvent:Connect(function(plr)
    local weapon, participant = allow(plr)
    if not weapon or not participant or weapon.Base.Kind == "Item" then
        return
    end

    print(weapon)

    InventoryManager.Reload(plr, weapon :: ItemTypes.Weapon)
end)