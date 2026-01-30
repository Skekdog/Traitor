
local function Modify<T>(original: T & {[any]: any}, newName: string, edit: {[any]: any}): T
	local new = table.clone(original)
    for i, v in pairs(edit) do
        new[i] = if typeof(v) == "table" and v["__nil"] == true then nil else v
    end

    new.Name = newName

    if original.Model and not edit.Model then
        new.Model = original.Model:Clone();
        (new.Model :: PVInstance).Name = newName;
        (new.Model :: PVInstance).Parent = original.Model.Parent
    end

    return (new :: any) :: T
end

return Modify