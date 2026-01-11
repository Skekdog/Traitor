local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandardHighlights = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.Common.StandardHighlights)
local Interactables = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Interactables)
local Ammo = require(ReplicatedStorage.Shared.GameDefinition.Items.Ammo)
local ItemGroups = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemGroups)
local ItemDefinitions = require(ReplicatedStorage.Shared.GameDefinition.Items.Items)
local Types = require(script.Parent.Types)

local StandardGame = {}

StandardGame.ItemGroups = ItemGroups

function StandardGame.GetItem(name: string): Types.ItemComponents
	return ItemDefinitions[name] or error("Item not found: " .. name)
end

function StandardGame.GetItems(): {[string]: Types.ItemComponents}
	return ItemDefinitions
end

-- todo: this function is duplicated in ItemDefinitions
function StandardGame.CopyModify<T>(original: T & (Types.ItemComponents | Types.AmmoDefinition | Types.InteractableDefinition), newName: string, edit: {[string]: any}): T
	local new = table.clone(original)
    for i, v in edit do
        new[i] = if typeof(v) == "table" and v["__nil"] == true then nil else v
    end

    new.Name = newName

    if original.Model then
        new.Model = original.Model:Clone();
        (new.Model :: PVInstance).Name = newName;
        (new.Model :: PVInstance).Parent = original.Model.Parent
    end

    return (new :: any) :: T
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