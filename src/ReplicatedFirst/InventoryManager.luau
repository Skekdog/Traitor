local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ItemTypes = require(script.Parent.ItemsManager.ItemTypes)
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

module.AmmoData = { -- magazine, max
    ["Assault Rifle"] = {Magazine = 20, Max = 60},
    Shotgun = {Magazine = 8, Max = 16},
    Deagle = {Magazine = 8, Max = 32},
    SMG = {Magazine = 30, Max = 60},
    Scout = {Magazine = 5, Max = 10},
} :: {[ItemTypes.AmmoType]: {Magazine: number, Max: number, [number]: nil}}

local function runCallback(plr: Player, event: InventoryEvent, equipment: Item, switching: boolean?)
    for _, v in listeners[event] do
        v(plr, equipment, switching)
    end
end

module.Items = {} :: {[Instance]: Item | ItemTypes.Weapon}

function module.HasEquipment(plr: Player, equipment: Item): boolean
    return table.find(inventories[plr], equipment) ~= nil
end

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

function module.ClearAllReserves(): ()
    reserveAmmo = {}
end

function module.Reload(player: Player, weapon: ItemTypes.Weapon): ()
    local multiUse = weapon.Base.MultiUse
    if not multiUse then
        return
    end
    assert(typeof(multiUse) ~= "boolean")

    local ammoType: ItemTypes.AmmoType? = multiUse.AmmoType
    local reserve = module.GetReserve(player, ammoType)
    local char = player.Character

    if reserve <= 0 or not ammoType or not char or weapon.Reloading or weapon.CurrentAmmo == multiUse.MagazineSize or weapon.CurrentAmmo == math.huge then
        return
    end

    local reloadSound = weapon.Base.ReloadSound
    if reloadSound then
        reloadSound = reloadSound:Clone()
        reloadSound.Name = "ReloadSound"
        reloadSound.Parent = char.PrimaryPart
        reloadSound.Ended:Once(function()
            reloadSound:Destroy()
        end)
        reloadSound:Play()
    end

    weapon.Reloading = task.delay(multiUse.ReloadTime, function()
        weapon.Reloading = nil

        local prevAmmo = weapon.CurrentAmmo
        weapon.CurrentAmmo = math.min(weapon.CurrentAmmo + reserve, multiUse.MagazineSize or module.AmmoData[ammoType].Magazine)

        -- We need to GetReserve() again because they may have picked up more ammo whilst reloading
        module.SetReserve(player, ammoType, module.GetReserve(player, ammoType) - (weapon.CurrentAmmo - prevAmmo))
        module.UpdateAmmo(player)
    end)
end

function module.HasWeaponOfAmmoType(plr: Player, ammoType: ItemTypes.AmmoType): boolean
    for _, v in inventories[plr] do
        local weapon = v.Base
        if weapon.Kind == "Weapon" then
            if weapon.MultiUse and weapon.MultiUse.AmmoType == ammoType then
                return true
            end
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
        if (old :: any) ~= equipment then
            return
        end
        if old and old.Base.OnUnequip then
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

function module.ClearInventory(plr: Player)
    local equipment = inventories[plr]
    if not equipment then
        return
    end
    for i = #equipment, 1, -1 do
        module.RemoveEquipment(plr, equipment[i])
    end
end

function module.ClearAllItems()
    for i, _ in module.Items do
        i:Destroy()
    end
    table.clear(module.Items)
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
    if not weapon or weapon.Kind ~= "Weapon" then
        return
    end

    local current = weapon.CurrentAmmo
    if current == math.huge then
        return
    end

    local size: number
    local reserve: number

    if weapon.Base.MultiUse then
        local ammoType = weapon.Base.MultiUse.AmmoType
        if ammoType then
            size = module.AmmoData[ammoType :: ItemTypes.AmmoType].Magazine
            reserve = module.GetReserve(plr, weapon.Base.MultiUse.AmmoType)
        end
        if weapon.Base.MultiUse.MagazineSize then
            size = weapon.Base.MultiUse.MagazineSize
        end
    end

    if not reserve then
        reserve = 0
    end

    serverClient.AmmoUpdate:FireClient(plr, current, size, reserve)
end

function module.NewItem(base: ItemTypes.ItemDefinition | ItemTypes.WeaponDefinition, instance: Instance, participant: Types.Participant, onTouch: (BasePart, Types.Round, BasePart) -> ()): Item
    local itemInstance = {Base = base, Instance = instance:Clone(), Kind = base.Kind}
    if base.Kind ~= "Item" then -- You may think that an equality check would work. It does not.
        local multiUse = base.MultiUse
        if multiUse then
            assert(typeof(multiUse) ~= "boolean")
            if multiUse.MagazineSize then
                itemInstance.CurrentAmmo = multiUse.MagazineSize
            elseif multiUse.AmmoType then
                itemInstance.CurrentAmmo = module.AmmoData[multiUse.AmmoType].Magazine
            else
                itemInstance.CurrentAmmo = math.huge
            end
        end
        itemInstance.LastFireTime = 0
        (itemInstance.Instance :: BasePart).Touched:Connect(function(part)
            onTouch(itemInstance.Instance :: BasePart, participant.Round, part)
        end)
    end
    return itemInstance :: any
end

if IS_CLIENT then
    inventories[Players.LocalPlayer] = {}
end

return module