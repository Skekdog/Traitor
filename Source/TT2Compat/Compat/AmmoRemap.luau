
local remap = {
	["High-Cal"] = "Deagle",
	["Mil-Spec"] = "9mm",
	["SMG"] = "SMG1",
}

local function AmmoRemap(ammo: string): string
	return remap[ammo] or ammo
end

return AmmoRemap