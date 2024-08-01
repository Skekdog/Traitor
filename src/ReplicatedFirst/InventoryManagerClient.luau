local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmmoData = require(script.Parent.AmmoData)
local ItemTypes = require(script.Parent.ItemTypes)
local Items = require(script.Parent.Items)
local module = {}

module.Items = {} :: {[string]: ItemTypes.Item?}
module.Equipped = nil :: ItemTypes.Item?

export type InventoryEvent = "Remove" | "Equip" | "Unequip" | "Drop" | "Add"
type InventoryRemote = {
    FireServer: (self: any, InventoryEvent, string, boolean?, Ray?) -> (),
    OnClientEvent: {Connect: (any, (event: InventoryEvent, equipment: string?) -> ()) -> RBXScriptConnection}
}
module.InvEvent = (ReplicatedStorage:WaitForChild("ServerClient").InventoryEvent :: any) :: InventoryRemote

local listeners: {[InventoryEvent]: {((ItemTypes.Item) -> ())}} = {Remove = {}, Equip = {}, Unequip = {}, Drop = {}, Add = {}}
local function runCallback(event: InventoryEvent, equipment: ItemTypes.Item)
    for _, v in listeners[event] do
        v(equipment)
    end
end

function module.Listen(event: InventoryEvent, callback: (ItemTypes.Item) -> ()): () -> ()
    table.insert(listeners[event], callback)
    return function()
        table.remove(listeners[event], table.find(listeners[event], callback))
    end
end

function module.LoadItem(name: string): ItemTypes.Item
    local base = Items[name]

    local item: ItemTypes.Item
    if base.Kind == "Gun" then
        local gunItem: ItemTypes.GunWeapon = {
            Base = base,
            Kind = "Gun",
            CurrentAmmo = base.MagazineSize or AmmoData[base.AmmoType :: any].Max,
            Instance = base.Model,
            Reloading = nil,
            LastFireTime = 0,
            LastFireAttempt = 0,
        }
        item = gunItem
    elseif base.Kind == "Melee" then
        local meleeItem: ItemTypes.MeleeWeapon = {
            Base = base,
            Kind = "Melee",
            Instance = base.Model,
            LastFireTime = 0,
        }
        item = meleeItem
    elseif base.Kind == "Grenade" then
        local grenadeItem: ItemTypes.GrenadeWeapon = {
            Base = base,
            Kind = "Grenade",
            Instance = base.Model,
        }
        item = grenadeItem
    elseif base.Kind == "Item" then
        local itemItem: ItemTypes.Item = {
            Base = base,
            Kind = "Item",
            Instance = base.Model,
        }
        item = itemItem
    end

    module.Items[name] = item
    return item
end

function module.AddEquipment(equipment: string): ItemTypes.Item
    local item = module.LoadItem(equipment)
    runCallback("Add", item)
    return item
end

function module.RemoveEquipment(equipment: ItemTypes.Item)
    module.Unequip(equipment)
    if module.Items[equipment.Base.Name] then
        module.Items[equipment.Base.Name] = nil
    end
    if not equipment.Base.CanDrop then
        equipment.Instance:Destroy()
    end
    runCallback("Remove", equipment)
end

function module.Equip(item: ItemTypes.Item)
    local base = item.Base
    module.Equipped = item
    module.InvEvent:FireServer("Equip", base.Name)
    if base.Kind == "Item" and base.OnEquipClient then
        base.OnEquipClient()
    end

    runCallback("Equip", item)
end

function module.Unequip(item: ItemTypes.Item)
    local base = item.Base
    module.InvEvent:FireServer("Unequip", base.Name)
    if base.Kind == "Item" and base.OnUnequipClient then
        base.OnUnequipClient()
    end

    local old = module.Equipped
    if old and old.Base.Name == base.Name then
        module.Equipped = nil
    end

    runCallback("Unequip", item)
end

function module.Drop(item: ItemTypes.Item, cameraRayInfo: Ray)
    if not item.Base.CanDrop then
        return
    end
    module.InvEvent:FireServer("Drop", item.Base.Name, nil, cameraRayInfo)
    runCallback("Drop", item)
end

return module