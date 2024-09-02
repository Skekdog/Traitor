local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManagerServer = require(script.Parent.InventoryManagerServer)

type Item = {
    Kind: "Ammo" | "Weapon",
    Name: string,
    AmmoType: string?,
    AmmoAvailable: number?,
}

return function(players: {Player}, instance: Instance): ()
    assert(instance:IsDescendantOf(workspace))

    local data: Item

    local isAmmo = instance.Name:split("_")[2] == "Ammo"
    if isAmmo then
        local ammo = InventoryManagerServer.AmmoBoxes[instance]
        data = {
            Kind = "Ammo",
            Name = instance.Name:split("_")[1],
            AmmoAvailable = ammo
        }
    else
        local item = InventoryManagerServer.Items[instance]
        data = {
            Kind = "Weapon",
            Name = item.Base.Name,
            AmmoType = if item.Kind == "Gun" then item.Base.AmmoType else nil,
            AmmoAvailable = if item.Kind == "Gun" then item.CurrentAmmo else nil,
        }
    end

    for _, v in players do
        ReplicatedStorage.ServerClient.NewDroppedItem:FireClient(v, instance, data)
    end
end
