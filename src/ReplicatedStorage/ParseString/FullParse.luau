
local children = script.Parent:GetChildren()
local parsers: {(string) -> string} = {}

for _, v in children do
	if v ~= script and v:IsA("ModuleScript") then
		local result = (require)(v)
		if typeof(result) == "function" then
			table.insert(parsers, result)
		end
	end
end

local function FullParse(str: string): string
	for _, v in parsers do
		str = v(str)
	end

	return str
end

return FullParse