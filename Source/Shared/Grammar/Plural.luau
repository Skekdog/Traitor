
local function Plural(count: number, singular: string, plural: string): string
	return if count == 1 then singular else plural
end

return Plural