
local function CombineTable<T>(table1: {T}, table2: {T}): {T}
	local new = {}
	table.move(table1, 1, #table1, 1, new)
	table.move(table2, 1, #table2, #new + 1, new)
	return new
end

return CombineTable