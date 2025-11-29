local GetDeterminer = require(script.Parent.GetDeterminer)

return function(str: string): string
	local determiner = GetDeterminer(str)
	return determiner .. " " .. str
end