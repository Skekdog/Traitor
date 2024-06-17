local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local WeaponsTypes = require(script.Parent.WeaponsManager.WeaponsTypes)
local module = {}

-- This can be used from both the client and the server.

export type Inventory = {WeaponsTypes.Weapon}
local inventories: {[Player]: Inventory} = {}
local equipped: {[Player]: WeaponsTypes.Weapon?} = {}

export type InventoryEvent = "Add" | "Remove" | "Equip" | "Unequip"
local listeners: {[InventoryEvent]: {((Player, WeaponsTypes.Weapon) -> ())}} = {Add = {}, Remove = {}, Equip = {}, Unequip = {}}

local IS_CLIENT = RunService:IsClient()

type InventoryRemote = {
    FireServer: (self: any, InventoryEvent, WeaponsTypes.WeaponName) -> (),
    FireClient: (self: any, Player, InventoryEvent, WeaponsTypes.Weapon) -> (),
    OnServerEvent: {Connect: (self: any, (Player, InventoryEvent?, WeaponsTypes.WeaponName?) -> ()) -> ()},
}

module.InvEvent = (ReplicatedStorage :: any):WaitForChild("ServerClient").InventoryEvent :: InventoryRemote

local function runCallback(plr: Player, event: InventoryEvent, equipment: WeaponsTypes.Weapon)
    for _, v in listeners[event] do
        v(plr, equipment)
    end
end

function module.HasEquipment(plr: Player, equipment: WeaponsTypes.Weapon): boolean
    return table.find(inventories[plr], equipment) ~= nil
end

function module.AddEquipment(plr: Player, equipment: WeaponsTypes.Weapon)
    table.insert(inventories[plr], equipment)
    runCallback(plr, "Add", equipment)
end

function module.RemoveEquipment(plr: Player, equipment: WeaponsTypes.Weapon)
    module.Unequip(plr, equipment)
    table.remove(inventories[plr], table.find(inventories[plr], equipment))
    runCallback(plr, "Remove", equipment)
end

function module.GetInventory(plr: Player): Inventory
    return inventories[plr]
end

function module.GetEquipped(plr: Player): WeaponsTypes.Weapon?
    return equipped[plr]
end

function module.Equip(plr: Player, equipment: WeaponsTypes.Weapon)
    if IS_CLIENT then
       module.InvEvent:FireServer("Equip", equipment.Name)
    else
        local old = equipped[plr]
        if old == equipment then
            return
        end
        if old then
            module.Unequip(plr, old)
        end

        print("Equip", equipment.Name)
        equipped[plr] = equipment
        -- server code for equipping
    end
    runCallback(plr, "Equip", equipment)
end

function module.Unequip(plr: Player, equipment: WeaponsTypes.Weapon)
    if IS_CLIENT then
        module.InvEvent:FireServer("Unequip", equipment.Name)
    else
        local old = equipped[plr]
        if old ~= equipment then
            return
        end

        print("Unequip", equipment.Name)
        equipped[plr] = nil

        -- server code for unequipping
    end
    runCallback(plr, "Unequip", equipment)
end

function module.Drop(plr: Player, equipment: WeaponsTypes.Weapon)
    module.RemoveEquipment(plr, equipment)
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

function module.Listen(event: InventoryEvent, callback: (Player, WeaponsTypes.Weapon) -> ()): () -> ()
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