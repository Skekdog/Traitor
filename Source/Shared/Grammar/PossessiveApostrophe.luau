
local function PossessiveApostrophe(str: string): string
	return if str:sub(-1) == "s" then str .. "'" else str .. "'s"
end

return PossessiveApostrophe