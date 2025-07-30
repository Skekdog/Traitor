local remap = {
	["ThoseYouTrust"] = "Traitor Town"
}

local function GamemodeNameRemap(name: string): string
	return remap[name] or name
end

return GamemodeNameRemap