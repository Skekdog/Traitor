local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(script.Parent.Parent.ReplicatedFirst.RoundHandler.Types)
local module = {}

-- This can be used from both the client and the server.

export type Inventory = {Types.Equipment}
local inventories: {[Player]: Inventory} = {}

export type InventoryEvent = "Add" | "Remove" | "Equip" | "Unequip"
local listeners: {[InventoryEvent]: {((Player, Types.Equipment) -> ())}} = {Add = {}, Remove = {}, Equip = {}, Unequip = {}}

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()

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

function module.Equip(plr: Player, equipment: Types.Equipment)
    if IS_CLIENT then
        (ReplicatedStorage :: any):WaitForChild("ServerClient").InventoryEvent:FireServer("Equip", equipment.Name)
    else
        -- server code for equipping
    end
    runCallback(plr, "Equip", equipment)
end

function module.Unequip(plr: Player, equipment: Types.Equipment)
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
    end);

    local function fireClient(plr: Player, event: InventoryEvent, equipment: Types.Equipment)
        (ReplicatedStorage :: any):WaitForChild("ServerClient").InventoryEvent:FireClient(plr, event, equipment)
    end

    module.Listen("Add", function(plr, equipment)
        fireClient(plr, "Add", equipment)
    end)
    module.Listen("Remove", function(plr, equipment)
        fireClient(plr, "Remove", equipment)
    end)
end

if IS_CLIENT then
    inventories[Players.LocalPlayer] = {}
end

return module