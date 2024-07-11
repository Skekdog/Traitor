local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ItemTypes = require(script.Parent.ItemsManager.ItemTypes)
local Items = require(script.Parent.ItemsManager.Items)
local Types = require(script.Parent.RoundHandler.Types)
local module = {}

-- This can be used from both the client and the server.

type Item = ItemTypes.Item | ItemTypes.Weapon

export type Inventory = {Item}
local inventories: {[Player]: Inventory} = {}
local equipped: {[Player]: Item?} = {}

export type InventoryEvent = "Add" | "Remove" | "Equip" | "Unequip" | "Drop"
local listeners: {[InventoryEvent]: {((Player, Item, boolean?) -> ())}} = {Add = {}, Remove = {}, Equip = {}, Unequip = {}, Drop = {}}

local IS_CLIENT = RunService:IsClient()

type InventoryRemote = {
    FireServer: (self: any, InventoryEvent, string, boolean?) -> (),
    FireClient: (self: any, Player, InventoryEvent, Item) -> (),
    OnServerEvent: {Connect: (self: any, (Player, InventoryEvent?, string?, boolean?) -> ()) -> ()},
}

local serverClient = ReplicatedStorage:WaitForChild("ServerClient") :: typeof(ReplicatedStorage.ServerClient)
module.InvEvent = (serverClient.InventoryEvent :: any) :: InventoryRemote

local ammoData: {[string]: {Magazine: number, Max: number, [number]: nil}} = {
    ["Assault Rifle"] = {Magazine = 20, Max = 60},
    Shotgun = {Magazine = 8, Max = 16},
    Deagle = {Magazine = 8, Max = 32},
    SMG = {Magazine = 30, Max = 60},
    Scout = {Magazine = 5, Max = 10},
}

module.AmmoData = ammoData

local function runCallback(plr: Player, event: InventoryEvent, equipment: Item, switching: boolean?)
    for _, v in listeners[event] do
        v(plr, equipment, switching)
    end
end

module.Items = {} :: {[Instance]: Item | ItemTypes.Weapon}

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
    local reserve = module.GetReserve(player, ammoType)
    local char = player.Character

    if reserve <= 0 or not ammoType or not char or weapon.Reloading or weapon.CurrentAmmo == base.MagazineSize then
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

    weapon.Reloading = task.delay(base.ReloadTime, function()
        weapon.Reloading = nil

        local prevAmmo = weapon.CurrentAmmo
        weapon.CurrentAmmo = math.min(weapon.CurrentAmmo + reserve, base.MagazineSize or module.AmmoData[ammoType].Magazine)

        -- We need to GetReserve() again because they may have picked up more ammo whilst reloading
        module.SetReserve(player, ammoType, module.GetReserve(player, ammoType) - (weapon.CurrentAmmo - prevAmmo))
        module.UpdateAmmo(player)
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
    runCallback(plr, "Remove", equipment)
end

function module.GetInventory(plr: Player): Inventory
    return inventories[plr]
end

function module.GetEquipped(plr: Player): Item?
    return equipped[plr]
end

function module.Equip(plr: Player, equipment: Item)
    if IS_CLIENT then
       module.InvEvent:FireServer("Equip", equipment.Base.Name)
       equipped[plr] = equipment
    else
        local old = equipped[plr]
        if (old :: any) == equipment then
            return
        end
        if old then
            module.Unequip(plr, old, true)
        end

        equipped[plr] = equipment
        -- server code for equipping
    end
    runCallback(plr, "Equip", equipment)
end

function module.Unequip(plr: Player, equipment: Item, switching: boolean?)
    if IS_CLIENT then
        module.InvEvent:FireServer("Unequip", equipment.Base.Name, switching)
        local old = equipped[plr]
        if old and old.Base.Name == equipment.Base.Name then
            equipped[plr] = nil
        end
    else
        local old = equipped[plr]
        if old ~= equipment then
            return
        end
        if old and old.Kind == "Item" and old.Base.OnUnequip then
            old.Base.OnUnequip(plr)
        end
        equipped[plr] = nil
    end
    runCallback(plr, "Unequip", equipment, switching)
end

function module.Drop(plr: Player, equipment: Item, position: Vector3)
    if not equipment.Base.CanDrop then
        return
    end
    if IS_CLIENT then
        module.InvEvent:FireServer("Drop", equipment.Base.Name)
    else
        local spawns = (ReplicatedStorage.RoundHandler.MapFolder.Value :: Types.MapStructureCast):FindFirstChild("WeaponSpawns")
        equipment.Instance.Parent = spawns
        equipment.Instance:PivotTo(CFrame.new(position))
        module.RemoveEquipment(plr, equipment)
    end
    runCallback(plr, "Drop", equipment)
end

function module.DropAmmo(plr: Player, weapon: ItemTypes.GunWeapon)
    local base = weapon.Base

    local ammoType: ItemTypes.AmmoType = base.AmmoType :: ItemTypes.AmmoType
    if not ammoType then
        return
    end

    local char = plr.Character
    if not char then
        return
    end

    -- this is if we want to use reserve ammo

    -- local reserve = module.GetReserve(plr, ammoType)
    -- if reserve <= 0 then
    --     return
    -- end
    -- local amount = math.min(ammoData[ammoType].Magazine, reserve)
    -- module.SetReserve(plr, ammoType, reserve - amount)

    local amount = weapon.CurrentAmmo
    if amount <= 0 then
        return
    end

    weapon.CurrentAmmo = 0
    module.UpdateAmmo(plr)

    local box = ServerStorage.AmmoBoxes:FindFirstChild(ammoType.."_Ammo"):Clone() :: PVInstance
    module.NewAmmoBox(box, amount)
    box:PivotTo(CFrame.new(char:GetPivot().Position + char:GetPivot().LookVector * 10))
    box.Parent = (ReplicatedStorage.RoundHandler.MapFolder.Value :: Types.MapStructureCast):FindFirstChild("WeaponSpawns")
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
    if current == math.huge then
        return
    end

    local size: number?
    local reserve: number

    local base = weapon.Base

    local ammoType = base.AmmoType
    if base.MagazineSize then
        size = base.MagazineSize
    elseif ammoType then
        size = module.AmmoData[ammoType :: ItemTypes.AmmoType].Magazine
        reserve = module.GetReserve(plr, base.AmmoType)
    end

    assert(size, "One of AmmoType or MagazineSize must be set")

    if not reserve then
        reserve = 0
    end

    serverClient.AmmoUpdate:FireClient(plr, current, size, reserve)
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
        local ammoData = module.AmmoData[ammoType]
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

    local item = module.Items[weapon] :: ItemTypes.Item
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
        module.NewItem(base, weapon, participant)
    end

    module.AddEquipment(participant.Player, module.Items[weapon])
    weapon.Parent = nil
end

function module.NewItem(base: ItemTypes.ItemDefinition | ItemTypes.WeaponDefinition, instance: Instance?, participant: Types.Participant): Item
    if not instance then
        instance = base.Model
    end
    assert(instance)

    instance = instance:Clone()
    assert(instance:IsA("BasePart") and instance:IsA("PVInstance"))

    local itemInstance: ItemTypes.Item = {} :: ItemTypes.Item

    if base.Kind == "Gun" then
        if not base.MagazineSize and not base.AmmoType then
            error("One of MagazineSize or AmmoType must be set")
        end
        
        local currentAmmo = base.MagazineSize or module.AmmoData[base.AmmoType :: ItemTypes.AmmoType].Magazine
        local gunInstance: ItemTypes.GunWeapon = {
            Base = base,
            Instance = instance,
            Kind = "Gun",

            CurrentAmmo = currentAmmo,
            LastFireTime = 0,
            LastFireAttempt = 0,
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

    (itemInstance.Instance :: BasePart).Touched:Connect(function(part)
        module.OnItemTouched(itemInstance.Instance :: BasePart, participant.Round, part)
    end)

    module.Items[itemInstance.Instance] = itemInstance :: any
    module.AddEquipment(participant.Player, itemInstance :: any)

    return itemInstance :: any
end

function module.NewAmmoBox(box: Instance, amount: number?): number
    module.AmmoBoxes[box] = amount or ammoData[box.Name:split("_")[1]].Magazine
    return module.AmmoBoxes[box]
end

if IS_CLIENT then
    inventories[Players.LocalPlayer] = {}
end

return module