local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(script.Parent.Parent.ReplicatedFirst.RoundHandler.Types)
local module = {}

-- This can be used from both the client and the server.

export type Inventory = {Types.Equipment}
local inventories: {[Player]: Inventory} = {}
local equipped: {[Player]: Types.Equipment?} = {}

export type InventoryEvent = "Add" | "Remove" | "Equip" | "Unequip"
local listeners: {[InventoryEvent]: {((Player, Types.Equipment) -> ())}} = {Add = {}, Remove = {}, Equip = {}, Unequip = {}}

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()

type InventoryRemote = {
    FireServer: (self: any, InventoryEvent, Types.EquipmentName) -> (),
    FireClient: (self: any, Player, InventoryEvent, Types.Equipment) -> (),
    OnServerEvent: {Connect: (self: any, (Player, InventoryEvent?, Types.EquipmentName?) -> ()) -> ()},
}

local invEvent = (ReplicatedStorage :: any):WaitForChild("ServerClient").InventoryEvent :: InventoryRemote

local function runCallback(plr: Player, event: InventoryEvent, equipment: Types.Equipment)
    for _, v in listeners[event] do
        v(plr, equipment)
    end
end

function module.HasEquipment(plr: Player, equipment: Types.Equipment): boolean
    return table.find(inventories[plr], equipment) ~= nil
end

function module.AddEquipment(plr: Player, equipment: Types.Equipment)
    table.insert(inventories[plr], equipment)
    runCallback(plr, "Add", equipment)
end

function module.RemoveEquipment(plr: Player, equipment: Types.Equipment)
    table.remove(inventories[plr], table.find(inventories[plr], equipment))
    runCallback(plr, "Remove", equipment)
end

function module.GetInventory(plr: Player): Inventory
    return inventories[plr]
end

function module.GetEquipped(plr: Player): Types.Equipment?
    return equipped[plr]
end

function module.Equip(plr: Player, equipment: Types.Equipment)
    if IS_CLIENT then
       invEvent:FireServer("Equip", equipment.Name)
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

function module.Unequip(plr: Player, equipment: Types.Equipment)
    if IS_CLIENT then
        invEvent:FireServer("Unequip", equipment.Name)
    else
        local old = equipped[plr]
        if old ~= equipment or not old then
            return
        end

        print("Unequip", equipment.Name)
        equipped[plr] = nil

        -- server code for unequipping
    end
    runCallback(plr, "Unequip", equipment)
end

function module.Drop(plr: Player, equipment: Types.Equipment)
    module.RemoveEquipment(plr, equipment)
end

function module.ClearInventory(plr: Player)
    for _, v in inventories[plr] do
        module.RemoveEquipment(plr, v)
    end
end

function module.Listen(event: InventoryEvent, callback: (Player, Types.Equipment) -> ()): () -> ()
    table.insert(listeners[event], callback)
    return function()
        table.remove(listeners[event], table.find(listeners[event], callback))
    end
end

if IS_SERVER then
    for _, plr in Players:GetPlayers() do
        inventories[plr] = {}
    end
    Players.PlayerAdded:Connect(function(plr)
        inventories[plr] = {}
    end)
    Players.PlayerRemoving:Connect(function(plr)
        inventories[plr] = nil
        equipped[plr] = nil
    end)

    local function fireClient(plr: Player, event: InventoryEvent, equipment: Types.Equipment)
        invEvent:FireClient(plr, event, equipment)
    end

    module.Listen("Add", function(plr, equipment)
        fireClient(plr, "Add", equipment)
    end)
    module.Listen("Remove", function(plr, equipment)
        fireClient(plr, "Remove", equipment)
    end)

    invEvent.OnServerEvent:Connect(function(plr: Player, event: InventoryEvent?, equipmentName: Types.EquipmentName?)
        if typeof(equipmentName) ~= "string" then
            return
        end

        local inventory = inventories[plr]
        local foundEquipment: Types.Equipment?
        for _, v in inventory do
            if v.Name == equipmentName then
                foundEquipment = v
                break
            end
        end

        if not foundEquipment then
            return
        end

        if event == "Equip" then
            module.Equip(plr, foundEquipment)
        elseif event == "Unequip" then
            module.Unequip(plr, foundEquipment)
        end
    end)
end

if IS_CLIENT then
    inventories[Players.LocalPlayer] = {}
end

return module