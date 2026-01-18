local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local function Modify<T>(original: T & (Types.ItemComponents | Types.AmmoDefinition | Types.InteractableDefinition), newName: string, edit: {[string]: any}): T
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

return Modify