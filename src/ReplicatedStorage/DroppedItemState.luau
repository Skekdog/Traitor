local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}

-- Represents either ammo or a weapon
export type Item = {
    Kind: "Ammo" | "Weapon",
    Name: string,
    AmmoType: string?,
    AmmoAvailable: number?,
}

local droppedItems: {[Instance]: Item?} = {}

function module.GetDroppedItem(instance: Instance): Item
    return droppedItems[instance] or error("Item not found for instance " .. instance:GetFullName())
end

ReplicatedStorage:WaitForChild("ServerClient").NewDroppedItem.OnClientEvent:Connect(function(instance: Instance, item: Item)
    droppedItems[instance] = item
end)

return module