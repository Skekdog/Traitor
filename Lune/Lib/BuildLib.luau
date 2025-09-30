local process = require("@lune/process")
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local function Build(name: string, projectPath: string): roblox.DataModel
	local executionResult = process.exec("rojo", {"build", "--output", name, projectPath})
	assert(executionResult.ok, executionResult.stderr)

	local result = fs.readFile(name)
	local game = roblox.deserializePlace(result)

	return game
end

return Build