export type ItemState = {
    Kind: "ItemState",
    Name: string,
    StoredAmmo: number?,
    AmmoType: string?,

    IsAmmoBox: boolean,
}

local function GetDroppedItemState(instance: Instance): ItemState
    local storedAmmo = instance:GetAttribute("StoredAmmo")
    local ammoType = instance:GetAttribute("AmmoType")

    assert(not storedAmmo or typeof(storedAmmo) == "number", "Expected attribute 'StoredAmmo' to be a number")
    assert(not ammoType or typeof(ammoType) == "string", "Expected attribute 'AmmoType' to be a string")
    assert(instance.Parent, "Expected instance to have a parent")

    return {
        Kind = "ItemState",
        Name = instance.Name,
        StoredAmmo = storedAmmo,
        AmmoType = ammoType,

        IsAmmoBox = instance.Parent.Name == "AmmoSpawns",
    }
end

return GetDroppedItemState