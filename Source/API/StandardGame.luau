local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandardHighlights = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.Common.StandardHighlights)
local Interactables = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Interactables)
local Ammo = require(ReplicatedStorage.Shared.GameDefinition.Items.Ammo)
local ItemDefinitions = require(ReplicatedStorage.Shared.GameDefinition.Items.Items)
local Types = require(script.Parent.Types)

local StandardGame = {}

function StandardGame.GetItem(name: string): Types.ItemComponents
	return ItemDefinitions[name] or error("Item not found: " .. name)
end

function StandardGame.GetItems(): {[string]: Types.ItemComponents}
	return ItemDefinitions
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

return StandardGame