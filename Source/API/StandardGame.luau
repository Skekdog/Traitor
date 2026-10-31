local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandardHighlights = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.Common.StandardHighlights)
local Interactables = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Interactables)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local Types = require(script.Parent.Types)

local StandardGame = {}

local items: {[string]: Types.ItemComponents} = {}
for _, module in ReplicatedStorage.Shared.GameDefinition.Items:QueryDescendants("ModuleScript") do
    local ret = (require)(module)

    local name: string, value: Types.ItemComponents
    if ret.Item then
        name, value = ret.Item.Name, ret.Item
    else
        name, value = ret.Name, ret
    end

    if ret.ShopItem then
        name, value = ret.ShopItem.Name, ret.ShopItem
    end

    assert(not items[name], `Failed to register module "{module.Name}": Item with name "{name}" already exists`)

    items[name] = value
end

function StandardGame.GetItem(name: string): Types.ItemComponents
	return items[name] or error("Item not found: " .. name)
end

function StandardGame.GetItems(): {[string]: Types.ItemComponents}
	return items
end

function StandardGame.GetInteractable(name: string): Types.InteractableDefinition
    return Interactables[name] or error("Interactable not found: " .. name)
end

function StandardGame.GetInteractables(): {[string]: Types.InteractableDefinition}
    return Interactables
end

function StandardGame.GetAmmo(name: string): Types.AmmoDefinition
    return Ammo[name] or error("Ammo not found: " .. name)
end

function StandardGame.GetAllAmmo(): {[string]: Types.AmmoDefinition}
    return Ammo
end

StandardGame.Highlights = StandardHighlights

return table.freeze(StandardGame)