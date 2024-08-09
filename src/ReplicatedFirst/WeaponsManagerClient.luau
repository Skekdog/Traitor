local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AimWeaponClient = require(script.Parent.AimWeaponClient)
local AmmoData = require(script.Parent.AmmoData)
local InventoryManagerClient = require(script.Parent.InventoryManagerClient)
local ItemTypes = require(script.Parent.ItemTypes)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local SetAmmoBar = require(script.Parent.SetAmmoBar)
local Viewmodel = require(script.Parent.Viewmodel)

local clientServer = ReplicatedStorage:WaitForChild("ClientServer")

local module = {}

local function getCenterRay(): Ray
    local camera = workspace.CurrentCamera
    return camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
end

local function tryPlayEmptySound(weapon: ItemTypes.GunWeapon)
    local char = Players.LocalPlayer.Character
    if not char then
        return
    end

    local timeNow = workspace:GetServerTimeNow()
    if weapon.LastFireAttempt + weapon.Base.FireTime < timeNow then
        weapon.LastFireAttempt = timeNow
        local sound = ReplicatedStorage.WeaponSounds.EmptyClip:Clone()
        sound.Parent = char.PrimaryPart
        sound:Destroy()

        weapon.LastFireAttempt = timeNow
    end
end

-- Returns the time to wait until next shoot attempt
function module.PrimaryFire(item: ItemTypes.Item): number?
    if item.Kind == "Gun" then
        if item.ReloadingUntil == math.huge then
            return
        end

        if item.CurrentAmmo <= 0 then
            tryPlayEmptySound(item)
            return module.Reload(item)
        end

        -- No point in checking this on the server as cheaters gonna cheat cheat cheat
        if item.Base.ScopeRequired and not AimWeaponClient.IsAiming then
            return tryPlayEmptySound(item)
        end
    end

    if item.Kind == "Gun" or item.Kind == "Melee" then
        -- We add 0.01 to account for lag between server and client, as waiting a frame or two to shoot is better than missing an entire cycle
        if item.LastFireTime > workspace:GetServerTimeNow() - (item.Base.FireTime + 0.01) then
            return
        end
    end

    if item.Kind ~= "Item" then
        if item.Kind == "Gun" then
            module.SetAmmo(item.Base.Name, item.CurrentAmmo - 1)
        end
        if item.Kind == "Melee" or item.Kind == "Gun" then
            (item :: ItemTypes.MeleeWeapon).LastFireTime = workspace:GetServerTimeNow()
        end
        LocalRoundInfo.PrimaryFire(item)
    end
    clientServer.PrimaryFire:FireServer(getCenterRay())
    
    if item.Kind == "Gun" then
        return if item.CurrentAmmo <= 0 then nil else item.Base.FireTime
    elseif item.Kind == "Melee" then
        return item.Base.FireTime
    end

    return
end

function module.Reload(item: ItemTypes.Item): ()
    if item.Kind ~= "Gun" then
        return
    end

    local ammoType: ItemTypes.AmmoType = item.Base.AmmoType :: ItemTypes.AmmoType
    if not ammoType then
        return
    end

    local reserve = InventoryManagerClient.GetReserve(ammoType)
    if reserve <= 0 then
        return
    end

    local max = item.Base.MagazineSize or AmmoData[ammoType].Max
    if item.CurrentAmmo < max then
        item.ReloadingUntil = math.huge -- On client we fuhgetaboutit all and wait for the server to tell us we finished reloading
        Viewmodel.ReloadSpring.p = Vector3.new(10, 5, 10)

        -- Preferably we would use a RemoteFunction here and set reloadinguntil on the next line after invoking, but reloading is done with another thread on the server so that won't work (at least, not easily)
        ReplicatedStorage.ClientServer.ReloadWeapon:FireServer()
    end
end

function module.SetReloadingStatus(itemName: string): ()
    local item = InventoryManagerClient.Items[itemName]
    if not item or item.Kind ~= "Gun" then
        return
    end

    item.ReloadingUntil = 0
end


function module.SetAmmo(itemName: string, current: number, reserve: number?): ()
    local item = InventoryManagerClient.Items[itemName]
    if not item or item.Kind ~= "Gun" then
        return
    end

    if item.Base.AmmoType then
        if not reserve then
            reserve = InventoryManagerClient.GetReserve(item.Base.AmmoType)
        else
            InventoryManagerClient.SetReserve(item.Base.AmmoType, reserve)
        end
    else
        reserve = 0
    end
    assert(reserve)
    
    item.CurrentAmmo = current

    local magazineSize = item.Base.MagazineSize or AmmoData[item.Base.AmmoType :: ItemTypes.AmmoType].Magazine
    SetAmmoBar(current, magazineSize, reserve)
end

return module