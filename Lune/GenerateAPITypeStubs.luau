local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local poke_ast = require("./Lib/poke/ast/ast")
local PublishAsset = require("./Lib/PublishAsset")

local poke = {
	parser = require("./Lib/poke/ast/parser"),
	source = require("./Lib/poke/ast/source"),
}

-- So I thought that we could get away with simple string patterns
-- But actually its less complex to just use a full parser

local ASSET_ID = 116031459660559

local function getText(source: string, span: poke_ast.Span): string
	return string.sub(source, span.x + 1, span.y)
end

local STUB_BASE = [[
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
]]

local function baseStub(stats: {poke_ast.Stat}, cast: string, source: string): string
	local types = ""
	for _, stat in stats do
		if stat.kind == "type" then
			types ..= getText(source, stat.span) .. "\n"
		end
	end
	return STUB_BASE .. types .. "return (nil :: any) :: " .. cast
end

local function getFunctionType(stat: poke_ast.Stat_LocalFunction | poke_ast.Stat_Function, source: string): string
	local body = stat.body

	local generics = ""
	if body.generics then
		for _, generic in body.generics.names do
			generics ..= getText(source, generic.span) .. ", "
		end
		generics = generics:sub(1, -3)
		generics = "<" .. generics .. ">"
	end

	local parameters = ""
	for _, param in body.params do
		parameters ..= getText(source, param.name.span) .. ": " .. (if param.type then getText(source, param.type.span) else "any") .. ", "
	end
	parameters = parameters:sub(1, -3)

	local ret = if body.ret then getText(source, body.ret.span) else ""
	if ret == "()" then
		ret = "" -- "-> (())" is invalid type syntax :pensive:
	end

	return `{generics}({parameters}) -> ({ret})`
end

local function moduleStub(declStat: poke_ast.Stat_LocalVariable, stats: {poke_ast.Stat}, source: string): string
	local decl = declStat.bindings[1]
	local declName = getText(source, decl.name.span)

	local properties = ""

	for _, stat in stats do
		if stat.kind == "assign" or stat.kind == "function" then
			local left = if stat.kind == "assign" then stat.left[1].root else stat.names[1]
			local right = if stat.kind == "assign" then stat.right[1] else nil
			if getText(source, left.span) == declName then
				local name do
					local span = if stat.kind == "assign" then stat.left[1].suffixes[#stat.left[1].suffixes].span else stat.names[#stat.names].span
					name = getText(source, span)
					if stat.kind == "assign" then
						name = name:sub(2)
					end
				end
				if stat.kind == "assign" and right then
					local typeCast = if right.kind == "assertion" then getText(source, right.type.span) else "any"
					properties ..= "\n\t" .. name .. ": " .. typeCast .. ","
				elseif stat.kind == "function" then
					properties ..= "\n\t" .. name .. ": " .. getFunctionType(stat, source) .. ","
				end
			end
		end
	end

	if properties == "" then
		print("No properties found for " .. declName)
	end

	properties ..= "\n"

	return baseStub(stats, `\{{properties}}`, source)
end

local function functionStub(stat: poke_ast.Stat_LocalFunction, stats: {poke_ast.Stat}, source: string): string
	return baseStub(stats, getFunctionType(stat, source), source)
end

local function generateStub(script: string): string
	local source = poke.source.create(script)
	poke.parser.load(source)

	local block = poke.parser.parse_block()

	local retStat = block.last_stat
	assert(retStat and retStat.kind == "return", "Expected return statement")

	local ret = retStat.exprs[1]
	assert(ret, "Expected return value")

	assert(ret.kind == "var", "Only variables are supported for return")
	assert(ret.var.root.kind == "name", "Only direct variables are supported for return")

	local name do
		local span = ret.var.root.span
		name = getText(script, span)
	end

	local declarationStat: poke_ast.Stat_LocalFunction | poke_ast.Stat_LocalVariable?
	for i = #block.stats, 1, -1 do
		local stat = block.stats[i]
		if stat.kind == "localvariable" and getText(script, stat.bindings[1].name.span) == name then
			declarationStat = stat
			break
		elseif stat.kind == "localfunction" and getText(script, stat.name.span) == name then
			declarationStat = stat
			break
		end
	end

	assert(declarationStat, "Could not find declaration")

	local stub: string
	if declarationStat.kind == "localvariable" then
		stub = moduleStub(declarationStat, block.stats, script)
	else
		stub = functionStub(declarationStat, block.stats, script)
	end

	return stub
end

local function createScript(name: string, parent: roblox.Instance, stub: string): roblox.Instance
	local script = roblox.Instance.new("ModuleScript")
	script.Source = stub
	script.Name = name
	script.Parent = parent
	return script
end

local outputFolder = roblox.Instance.new("Folder")
outputFolder.Name = "API"

local function generateFile(path: string): ()
	local split = path:split("/")
	local file = split[#split]

	if file:sub(-5) ~= ".luau" then
		return
	end

	local name = file:sub(1, -6)

	local stub = generateStub(fs.readFile(path))
	createScript(name, outputFolder, stub)
end

for _, path in fs.readDir("Source/API") do
	generateFile("Source/API/" .. path)
end

createScript("Types", outputFolder, fs.readFile("Source/Shared/RoundRule/src/Types.luau"))

local output = roblox.serializeModel({outputFolder})
fs.writeFile("API.rbxm", output)

pcall(PublishAsset, ASSET_ID, "Traitor! API", "API.rbxm")
fs.removeFile("API.rbxm")