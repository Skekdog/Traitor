local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetAmmoDefinition = require(script.Parent.GetAmmoDefinition)
local GetItemDefinition = require(script.Parent.GetItemDefinition)
local Types = require(ReplicatedStorage.API.Types)

type ItemState = {
    Kind: "ItemState",
    Definition: Types.ItemComponents,
    StoredAmmo: number?,
    AmmoType: string?,
}

type AmmoState = {
    Kind: "AmmoState",
    Definition: Types.AmmoDefinition,
    StoredAmmo: number,
    AmmoType: string,
}

local function GetDroppedItemState(instance: Instance): ItemState | AmmoState
    assert(instance.Parent, "Expected instance to have a parent")
    local isAmmoBox = instance:HasTag("AmmoBox")

    local storedAmmo = instance:GetAttribute("StoredAmmo")
    local ammoType = instance:GetAttribute("AmmoType")

    if isAmmoBox then
        assert(typeof(storedAmmo) == "number", "Expected attribute 'StoredAmmo' to be a number")
        assert(typeof(ammoType) == "string", "Expected attribute 'AmmoType' to be a string")

        return {
            Kind = "AmmoState",
            Definition = GetAmmoDefinition(ammoType),
            StoredAmmo = storedAmmo,
            AmmoType = ammoType,
        }
    end

    assert(not storedAmmo or typeof(storedAmmo) == "number", "Expected attribute 'StoredAmmo' to be a number")
    assert(not ammoType or typeof(ammoType) == "string", "Expected attribute 'AmmoType' to be a string")

    return {
        Kind = "ItemState",
        Definition = assert(GetItemDefinition(instance.Name), "Item not found: " .. instance.Name),
        StoredAmmo = storedAmmo,
        AmmoType = ammoType,
    }
end

return GetDroppedItemState