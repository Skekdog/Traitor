local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmmoData = require(script.Parent.AmmoData)
local ItemTypes = require(script.Parent.ItemTypes)
local Items = require(script.Parent.Items)
local SetAmmoBar = require(script.Parent.SetAmmoBar)
local module = {}

module.Items = {} :: {[string]: ItemTypes.Item?}
module.Equipped = nil :: ItemTypes.Item?

local reserveAmmo: {[ItemTypes.AmmoType?]: number?} = {}
function module.GetReserve(ammoType: ItemTypes.AmmoType?): number
    return reserveAmmo[ammoType] or 0
end

function module.SetReserve(ammoType: ItemTypes.AmmoType, amount: number): ()
    reserveAmmo[ammoType] = amount
end

export type InventoryEvent = "Remove" | "Equip" | "Unequip" | "Drop" | "Add"
type InventoryRemote = {
    FireServer: (self: InventoryRemote, InventoryEvent, string, boolean?, Ray?) -> (),
    OnClientEvent: {Connect: (any, (event: InventoryEvent, equipment: string?) -> ()) -> RBXScriptConnection}
}
module.InvEvent = (ReplicatedStorage:WaitForChild("ServerClient").InventoryEvent :: Instance & InventoryRemote) :: InventoryRemote

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

function module.LoadItem(name: string, params: ItemTypes.ClientItemInitParams?): ItemTypes.Item
    local base = Items[name]

    local item: ItemTypes.Item
    if base.Kind == "Gun" then
        assert(params and params.CurrentAmmo and params.ReloadingUntil)
        local gunItem: ItemTypes.GunWeapon = {
            Base = base,
            Kind = "Gun",
            CurrentAmmo = params.CurrentAmmo,
            Instance = base.Model,
            Reloading = task.spawn(assert, true),
            LastFireTime = params.LastFireTime,
            LastFireAttempt = params.LastFireTime,
            ReloadingUntil = 0,
        }
        task.delay(params.ReloadingUntil - workspace:GetServerTimeNow(), function()
            gunItem.Reloading = nil
        end)
        item = gunItem
    elseif base.Kind == "Melee" then
        assert(params)
        local meleeItem: ItemTypes.MeleeWeapon = {
            Base = base,
            Kind = "Melee",
            Instance = base.Model,
            LastFireTime = params.LastFireTime,
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

function module.AddEquipment(equipment: string, params: ItemTypes.ClientItemInitParams?): ItemTypes.Item
    local item = module.LoadItem(equipment, params)
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

    if item.Kind == "Gun" then
        local ammoType: ItemTypes.AmmoType? = item.Base.AmmoType :: ItemTypes.AmmoType?
        SetAmmoBar(item.CurrentAmmo, item.Base.MagazineSize or AmmoData[ammoType :: ItemTypes.AmmoType].Magazine, module.GetReserve(ammoType))
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