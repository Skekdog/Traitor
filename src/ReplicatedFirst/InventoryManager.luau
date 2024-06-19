local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ItemTypes = require(script.Parent.ItemsManager.ItemTypes)
local module = {}

-- This can be used from both the client and the server.

export type Inventory = {ItemTypes.Item}
local inventories: {[Player]: Inventory} = {}
local equipped: {[Player]: ItemTypes.Item?} = {}

export type InventoryEvent = "Add" | "Remove" | "Equip" | "Unequip" | "Drop"
local listeners: {[InventoryEvent]: {((Player, ItemTypes.Item) -> ())}} = {Add = {}, Remove = {}, Equip = {}, Unequip = {}, Drop = {}}

local IS_CLIENT = RunService:IsClient()

type InventoryRemote = {
    FireServer: (self: any, InventoryEvent, string) -> (),
    FireClient: (self: any, Player, InventoryEvent, ItemTypes.Item) -> (),
    OnServerEvent: {Connect: (self: any, (Player, InventoryEvent?, string?) -> ()) -> ()},
}

module.InvEvent = (ReplicatedStorage :: any):WaitForChild("ServerClient").InventoryEvent :: InventoryRemote

local function runCallback(plr: Player, event: InventoryEvent, equipment: ItemTypes.Item)
    for _, v in listeners[event] do
        v(plr, equipment)
    end
end

module.Items = {} :: {[Instance]: ItemTypes.Item}

function module.HasEquipment(plr: Player, equipment: ItemTypes.Item): boolean
    return table.find(inventories[plr], equipment) ~= nil
end

function module.AddEquipment(plr: Player, equipment: ItemTypes.Item)
    table.insert(inventories[plr], equipment)
    runCallback(plr, "Add", equipment)
end

function module.RemoveEquipment(plr: Player, equipment: ItemTypes.Item)
    module.Unequip(plr, equipment)
    table.remove(inventories[plr], table.find(inventories[plr], equipment))
    runCallback(plr, "Remove", equipment)
end

function module.GetInventory(plr: Player): Inventory
    return inventories[plr]
end

function module.GetEquipped(plr: Player): ItemTypes.Item?
    return equipped[plr]
end

function module.Equip(plr: Player, equipment: ItemTypes.Item)
    if IS_CLIENT then
       module.InvEvent:FireServer("Equip", equipment.Base.Name)
       equipped[plr] = equipment
    else
        local old = equipped[plr]
        if (old :: any) == equipment then
            return
        end
        if old then
            module.Unequip(plr, old)
        end

        equipped[plr] = equipment
        -- server code for equipping
    end
    runCallback(plr, "Equip", equipment)
end

function module.Unequip(plr: Player, equipment: ItemTypes.Item)
    if IS_CLIENT then
        module.InvEvent:FireServer("Unequip", equipment.Base.Name)
    else
        local old = equipped[plr]
        if (old :: any) ~= equipment then
            return
        end
        equipped[plr] = nil
    end
    runCallback(plr, "Unequip", equipment)
end

function module.Drop(plr: Player, equipment: ItemTypes.Item, position: Vector3)
    if not equipment.Base.CanDrop then
        return
    end
    if IS_CLIENT then
        module.InvEvent:FireServer("Drop", equipment.Base.Name)
    else
        local spawns = (ReplicatedStorage :: any).RoundHandler.MapFolder.Value:FindFirstChild("WeaponSpawns")
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

function module.Listen(event: InventoryEvent, callback: (Player, ItemTypes.Item) -> ()): () -> ()
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

if IS_CLIENT then
    inventories[Players.LocalPlayer] = {}
end

return module