local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemDefinitions = require(ReplicatedStorage.Shared.GameDefinition.Items.Items)
local Types = require(script.Parent.Types)

local Items = {}

function Items.GetItem(name: string): Types.AnyItemDefinition
	return ItemDefinitions[name] or error("Item not found: " .. name)
end

function Items.GetItems(): {[string]: Types.AnyItemDefinition}
	return ItemDefinitions
end

-- todo: this function is duplicated in ItemDefinitions
function Items.CopyModify<T>(original: T & Types.AnyItemDefinition, newName: string, edit: {[string]: any}): Types.AnyItemDefinition
	local new = table.clone(original)
    for i, v in edit do
        new[i] = v
    end

    new.Name = newName

    if original.Model then
        new.Model = original.Model:Clone();
        (new.Model :: PVInstance).Name = newName;
        (new.Model :: PVInstance).Parent = ReplicatedStorage.Assets.WeaponModels
    end

    return new
end

return Items