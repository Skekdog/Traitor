local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local AmmoData = require(script.Parent.Parent.ReplicatedFirst.AmmoData)
local PlayAnimation = require(script.Parent.PlayAnimation)
local ItemTypes = require(ReplicatedFirst.ItemTypes)
local Items = require(ReplicatedFirst.Items)
local Types = require(ReplicatedFirst.RoundHandler.Types)
local module = {}

type Item = ItemTypes.Item | ItemTypes.Weapon

export type Inventory = {Item}
local inventories: {[Player]: Inventory} = {}
local equipped: {[Player]: Item?} = {}

export type InventoryEvent = "Add" | "Remove" | "Equip" | "Unequip" | "Drop"
local listeners: {[InventoryEvent]: {((Player, Item, boolean?) -> ())}} = {Add = {}, Remove = {}, Equip = {}, Unequip = {}, Drop = {}}

type InventoryRemote = {
    FireServer: (self: InventoryRemote, InventoryEvent, string, boolean?, Ray?) -> (),
    FireClient: (self: InventoryRemote, Player, InventoryEvent, string, ItemTypes.ClientItemInitParams?) -> (),
    OnServerEvent: {Connect: (self: any, (Player, InventoryEvent?, string?, boolean?) -> ()) -> ()},
}

local serverClient = ReplicatedStorage:WaitForChild("ServerClient")
module.InvEvent = (serverClient.InventoryEvent :: Instance & InventoryRemote) :: InventoryRemote

local function runCallback(plr: Player, event: InventoryEvent, equipment: Item, switching: boolean?)
    for _, v in listeners[event] do
        v(plr, equipment, switching)
    end
end

module.Items = {} :: {[Instance]: Item | ItemTypes.Weapon}
local aiming: {[Player]: boolean?} = {}

function module.IsAiming(plr: Player): boolean
    return aiming[plr] or false
end

function module.SetAiming(plr: Player, isAiming: boolean): ()
    aiming[plr] = isAiming
    ReplicatedStorage.ClientServer.AimWeapon:FireClient(plr, isAiming)
end

function module.HasEquipment(plr: Player, equipment: Item): boolean
    return table.find(inventories[plr], equipment) ~= nil
end

module.AmmoBoxes = {} :: {[Instance]: number}
local reserveAmmo: {[Player]: {[ItemTypes.AmmoType]: number?}?} = {}
function module.GetReserve(player: Player, ammoType: ItemTypes.AmmoType?): number
    local plrStore = reserveAmmo[player]
    if not plrStore or not ammoType then
        return 0
    end
    return plrStore[ammoType] or 0
end

function module.SetReserve(player: Player, ammoType: ItemTypes.AmmoType, reserve: number): ()
    local plrStore = reserveAmmo[player]
    if not plrStore then
        reserveAmmo[player] = {[ammoType] = reserve}
        return
    end
    plrStore[ammoType] = reserve
end

function module.Reset(): ()
    reserveAmmo = {}
    module.AmmoBoxes = {}

    for i, _ in module.Items do
        i:Destroy()
    end
    table.clear(module.Items)
end

function module.Reload(player: Player, weapon: ItemTypes.GunWeapon): ()
    local base = weapon.Base

    local ammoType: ItemTypes.AmmoType = base.AmmoType :: ItemTypes.AmmoType
    local maxAmmo = base.MagazineSize or AmmoData[ammoType].Magazine
    local reserve = module.GetReserve(player, ammoType)
    local char = player.Character

    if reserve <= 0 or not ammoType or not char or weapon.Reloading or weapon.CurrentAmmo == maxAmmo then
        return
    end

    local reloadSound = base.ReloadSound
    if reloadSound then
        reloadSound = reloadSound:Clone()
        reloadSound.Name = "ReloadSound"
        reloadSound.Parent = char.PrimaryPart
        reloadSound.Ended:Once(function()
            reloadSound:Destroy()
        end)
        reloadSound:Play()
    end

    weapon.ReloadingUntil = workspace:GetServerTimeNow() + base.ReloadTime
    weapon.Reloading = task.delay(base.ReloadTime, function()
        weapon.Reloading = nil

        local prevAmmo = weapon.CurrentAmmo
        weapon.CurrentAmmo = math.min(weapon.CurrentAmmo + reserve, maxAmmo)

        -- We need to GetReserve() again because they may have picked up more ammo whilst reloading
        module.SetReserve(player, ammoType, module.GetReserve(player, ammoType) - (weapon.CurrentAmmo - prevAmmo))
        module.UpdateAmmo(player)
        serverClient.SetReloadingStatus:FireClient(player, weapon.Base.Name)
    end)
end

function module.HasWeaponOfAmmoType(plr: Player, ammoType: ItemTypes.AmmoType): boolean
    for _, v in inventories[plr] do
        local weapon = v.Base
        if weapon.Kind == "Gun" and weapon.AmmoType == ammoType then
            return true
        end
    end
    return false
end

function module.AddEquipment(plr: Player, equipment: Item)
    table.insert(inventories[plr], equipment)
    runCallback(plr, "Add", equipment)
end

function module.RemoveEquipment(plr: Player, equipment: Item)
    module.Unequip(plr, equipment)
    table.remove(inventories[plr], table.find(inventories[plr], equipment))
    if not equipment.Base.CanDrop then
        equipment.Instance:Destroy()
    end
    runCallback(plr, "Remove", equipment)
end

function module.GetInventory(plr: Player): Inventory
    return inventories[plr]
end

function module.GetEquipped(plr: Player): Item?
    return equipped[plr]
end

function module.Equip(plr: Player, equipment: Item)
    local old = equipped[plr]
    if old == equipment then
        return
    end
    if old then
        module.Unequip(plr, old, true)
    end

    equipped[plr] = equipment

    if equipment.Base.HoldAnimation then
        local instance = equipment.Instance
        instance.Name = "Item"

        local char = PlayAnimation(plr, equipment.Base.HoldAnimation, equipment.Base.Name.."HoldAnimation")
        if not char then
            return
        end

        local motor = instance:FindFirstChildOfClass("Motor6D") or Instance.new("Motor6D")
        if not motor.Parent then
            motor.Part0 = char:FindFirstChild("RightHand") :: BasePart?
            motor.Part1 = instance

            local c1 = equipment.Base.Model:GetAttribute("AnimC1")
            if typeof(c1) == "CFrame" then
                motor.C1 = c1
            end

            motor.Parent = instance
        end

        instance.CanCollide = false
        instance.CanTouch = false
        instance.CanQuery = false
        instance.Parent = char
    end
    runCallback(plr, "Equip", equipment)
end

local priorities = {Enum.AnimationPriority.Action, Enum.AnimationPriority.Action2} -- hold and hit / aim animations
function module.Unequip(plr: Player, equipment: Item, switching: boolean?)
    module.SetAiming(plr, false)
    local old = equipped[plr]
    if old ~= equipment then
        return
    end
    if old and old.Kind == "Item" and old.Base.OnUnequip then
        old.Base.OnUnequip(plr)
    end
    equipped[plr] = nil

    local char = plr.Character
    if not char then
        return
    end

    if old and old.Instance.Parent == char then
        old.Instance.Parent = nil
    end

    local motor = equipment.Instance:FindFirstChildOfClass("Motor6D")
    if motor then
        motor:Destroy()
    end
    equipment.Instance.Parent = nil

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        return
    end

    for _, v in animator:GetPlayingAnimationTracks() do
        if table.find(priorities, v.Priority) and v.IsPlaying then
            v:Stop()
        end
    end
    runCallback(plr, "Unequip", equipment, switching)
end

local mapValue = ReplicatedStorage:WaitForChild("RoundHandler"):WaitForChild("MapFolder")
function module.Drop(plr: Player, equipment: Item, position: Vector3, cameraRayInfo: Ray?)
    if not equipment.Base.CanDrop then
        return
    end
    local spawns = (mapValue.Value :: Types.MapStructureCast):FindFirstChild("WeaponSpawns")

    local instance = equipment.Instance
    
    local motor = instance:FindFirstChildOfClass("Motor6D")
    if motor then
        motor:Destroy()
    end
    
    module.RemoveEquipment(plr, equipment)

    instance.Name = equipment.Base.Name
    instance:PivotTo(CFrame.new(position))

    instance.CollisionGroup = "DroppedWeapons"
    instance.CanCollide = true
    instance.CanTouch = true
    instance.CanQuery = true

    instance.Parent = spawns
    runCallback(plr, "Drop", equipment)
end

function module.DropAmmo(plr: Player, weapon: ItemTypes.GunWeapon, cameraRayInfo: Ray)
    local base = weapon.Base

    local ammoType: ItemTypes.AmmoType = base.AmmoType :: ItemTypes.AmmoType
    if not ammoType then
        return
    end

    local char = plr.Character
    if not char then
        return
    end

    local max = AmmoData[ammoType].Magazine

    local amount = weapon.CurrentAmmo
    if amount < (max / 4) then
        return ReplicatedStorage.ServerClient.SendAlert:FireClient(plr, "You do not have enough ammo to drop a box!", "other")
    end

    weapon.CurrentAmmo = 0
    module.UpdateAmmo(plr)

    local box = (ServerStorage.AmmoBoxes:FindFirstChild(ammoType.."_Ammo") :: PVInstance):Clone()
    module.NewAmmoBox(box, amount)
    box:PivotTo(CFrame.new(char:GetPivot().Position + cameraRayInfo.Direction.Unit * 10))
    box.Parent = (mapValue.Value :: Types.MapStructureCast):FindFirstChild("WeaponSpawns")
end

function module.ClearInventory(plr: Player)
    local equipment = inventories[plr]
    if not equipment then
        return
    end
    for i = #equipment, 1, -1 do
        module.RemoveEquipment(plr, equipment[i])
    end
end

function module.Listen(event: InventoryEvent, callback: (Player, Item) -> ()): () -> ()
    table.insert(listeners[event], callback)
    return function()
        table.remove(listeners[event], table.find(listeners[event], callback))
    end
end

function module.InitInventory(plr: Player): ()
    inventories[plr] = {}
end

function module.DeInitInventory(plr: Player): ()
    inventories[plr] = nil
    equipped[plr] = nil
end

module.UpdateAmmo = function(plr: Player)
    local weapon = equipped[plr]
    if not weapon or weapon.Kind ~= "Gun" then
        return
    end

    local current = weapon.CurrentAmmo

    local size: number?
    local reserve: number

    local base = weapon.Base

    local ammoType = base.AmmoType
    if base.MagazineSize then
        size = base.MagazineSize
    elseif ammoType then
        size = AmmoData[ammoType :: ItemTypes.AmmoType].Magazine
        reserve = module.GetReserve(plr, base.AmmoType)
    end

    assert(size, "One of AmmoType or MagazineSize must be set")

    if not reserve then
        reserve = 0
    end

    serverClient.AmmoUpdate:FireClient(plr, weapon.Base.Name, current, reserve)
end

function module.OnItemTouched(weapon: BasePart, round: Types.Round, part: BasePart)
    local char = part.Parent :: Model
    local plr = Players:GetPlayerFromCharacter(char)
    if not plr then
        return
    end
    local participant = round:GetParticipant(plr.Name)
    if not participant then
        return
    end

    if weapon.Name:split("_")[2] == "Ammo" then
        local ammoType: ItemTypes.AmmoType = weapon.Name:split("_")[1] :: ItemTypes.AmmoType
        local ammoData = AmmoData[ammoType]
        local ammo = module.AmmoBoxes[weapon]

        if not ammo then
            return
        end

        if ammo <= 0 then
            return weapon:Destroy()
        end

        local currentReserve = module.GetReserve(plr, ammoType)
        if module.HasWeaponOfAmmoType(plr, ammoType) and currentReserve < ammoData.Max then
            local diff = math.min(ammo, ammoData.Magazine, ammoData.Max - currentReserve)
            module.AmmoBoxes[weapon] -= diff
            module.SetReserve(plr, ammoType, module.GetReserve(plr, ammoType) + diff)
            module.UpdateAmmo(plr)

            if ammo - diff <= 0 then
                weapon:Destroy()
            end
        end
        return
    end

    local item = module.Items[weapon] :: ItemTypes.Item?
    local base = if item then item.Base else Items[weapon.Name]

    if not base then
        return
    end

    for _, v in module.GetInventory(plr) do
        if v.Base.Slot == base.Slot then
            return
        end
    end
    
    if not item then
        item = module.NewItem(base, weapon, participant.Round, participant.Player)
    else
        module.AddEquipment(participant.Player, item)
    end

    weapon.Parent = nil
end

function module.NewItem(base: ItemTypes.ItemDefinition | ItemTypes.WeaponDefinition, instance: BasePart?, round: Types.Round, player: Player?): Item
    if not instance then
        instance = base.Model:Clone()
    end
    assert(instance)

    local itemInstance: ItemTypes.Item = {} :: ItemTypes.Item

    if base.Kind == "Gun" then
        if not base.MagazineSize and not base.AmmoType then
            error("One of MagazineSize or AmmoType must be set")
        end
        
        local currentAmmo = base.MagazineSize or AmmoData[base.AmmoType :: ItemTypes.AmmoType].Magazine
        local gunInstance: ItemTypes.GunWeapon = {
            Base = base,
            Instance = instance,
            Kind = "Gun",

            CurrentAmmo = currentAmmo,
            LastFireTime = 0,
            LastFireAttempt = 0,
            ReloadingUntil = 0,
        }

        itemInstance = gunInstance
    elseif base.Kind == "Melee" then
        local meleeInstance: ItemTypes.MeleeWeapon = {
            Base = base,
            Instance = instance,
            Kind = "Melee",

            LastFireTime = 0,
        }

        itemInstance = meleeInstance
    elseif base.Kind == "Grenade" then
        local grenadeInstance: ItemTypes.GrenadeWeapon = {
            Base = base,
            Instance = instance,
            Kind = "Grenade",
        }

        itemInstance = grenadeInstance
    elseif base.Kind == "Item" then
        local genericItemInstance: ItemTypes.GenericItem = {
            Base = base,
            Instance = instance,
            Kind = "Item",
        }

        itemInstance = genericItemInstance
    end

    module.Items[itemInstance.Instance] = itemInstance

    itemInstance.Instance.Touched:Connect(function(part)
        module.OnItemTouched(itemInstance.Instance :: BasePart, round, part)
    end)

    if player then
        module.AddEquipment(player, itemInstance)
    end

    return itemInstance
end

function module.NewAmmoBox(box: Instance, amount: number?): number
    module.AmmoBoxes[box] = amount or AmmoData[box.Name:split("_")[1]].Magazine
    return module.AmmoBoxes[box]
end

return module