local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local PublishAsset = require("./Lib/PublishAsset")
local Stubuau = require("./Lib/Stubuau/Stubuau")

local ASSET_ID = "117390899198330"

local STUB_BASE = [[
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
]]

local function createScript(name: string, parent: roblox.Instance, stub: string): roblox.Instance
	local script = roblox.Instance.new("ModuleScript")
	script.Source = stub
	script.Name = name
	script.Parent = parent
	return script
end

local outputFolder = roblox.Instance.new("Folder")
outputFolder.Name = "API"

local function generateFile(basePath: string, path: string): ()
	local relPath = path:split(basePath)[2]:sub(2)

	local split = relPath:split("/")
	local file = split[#split]

	if file:sub(-5) ~= ".luau" then
		return
	end

	local name = file:sub(1, -6)

	local stub = Stubuau.GenerateStub(STUB_BASE, fs.readFile(path), path)

	local parent = outputFolder
	for _, folder in split do
		if folder == file then
			break
		end

		-- note: lune seems to have a bug with Instance.new(..., parent) constructor
		local newParent = parent:FindFirstChild(folder) or roblox.Instance.new("Folder")
		newParent.Parent = parent
		newParent.Name = folder
		parent = newParent
	end

	createScript(name, parent, stub)
end

local function generateDirectory(basePath: string, dir: string?): ()
	dir = dir or basePath
	assert(dir)

	for _, path in fs.readDir(dir) do
		path = dir .. "/" .. path
		if fs.isFile(path) then
			generateFile(basePath, path)
		else
			generateDirectory(basePath, path)
		end
	end
end

generateDirectory("Source/API")

createScript("Types", outputFolder, fs.readFile("Source/Shared/RoundRule/src/Types.luau"))

local output = roblox.serializeModel({outputFolder})
fs.writeFile("API.rbxm", output)

PublishAsset(ASSET_ID, "API", "API.rbxm")
fs.removeFile("API.rbxm")