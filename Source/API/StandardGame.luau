local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandardHighlights = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.Common.StandardHighlights)
local Interactables = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Interactables)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local Types = require(script.Parent.Types)

local StandardGame = {}

local items: {[string]: Types.ItemComponents} = {}
for _, module in ReplicatedStorage.Shared.GameDefinition.Items:QueryDescendants("ModuleScript") do
    local ret = (require)(module)
    if ret.Item then
        items[ret.Item.Name] = ret.Item
    else
        items[ret.Name] = ret
    end

    if ret.ShopItem then
        items[ret.ShopItem.Name] = ret.ShopItem
    end
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