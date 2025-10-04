
local function GetMaterial(part: BasePart): string
	local materialOverride = part:GetAttribute("MaterialOverride")
	local material = if typeof(materialOverride) == "string" and materialOverride ~= "" then materialOverride else part.Material.Name
	return material
end

return GetMaterial