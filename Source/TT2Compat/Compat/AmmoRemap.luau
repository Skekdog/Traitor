
local remap = {
	["SMG"] = "Sub-Spec",
}

local function AmmoRemap(ammo: string): string
	return remap[ammo] or ammo
end

return AmmoRemap