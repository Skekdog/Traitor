local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local Base64 = require("./Lib/Base64")

local UNSAFE_DATA_LENGTH = 20

local projectData = fs.readFile("default.project.json")
local project = serde.decode("json", projectData)

local tree = project.tree or error("Missing tree in project file")
local projectWorkspace = tree.Workspace or error("Missing Workspace in project file")
local workspacePath = projectWorkspace["$path"] or error("Missing $path in Workspace")

local workspaceFilePath = workspacePath .. "/init.meta.json"
if not fs.isFile(workspaceFilePath) then
	error("Missing Workspace init.meta.json")
end

local workspaceData = serde.decode("json", fs.readFile(workspaceFilePath))

local inputFile = process.args[1] or error("Missing input argument")

local inputData = fs.readFile(inputFile)

local game = roblox.deserializePlace(inputData)
local workspace = game:GetService("Workspace")

local collisionGroupData: string = (workspace :: any).CollisionGroupData
if not collisionGroupData or #collisionGroupData < UNSAFE_DATA_LENGTH then
	error("Invalid CollisionGroupData")
end

local properties = workspaceData.properties or {}
properties.CollisionGroupData = {
	BinaryString = buffer.tostring(Base64.encode(buffer.fromstring(collisionGroupData)))
}

local newWorkspaceData = {}
for k, v in workspaceData do
	newWorkspaceData[k] = v
end

newWorkspaceData.properties = properties
local encodedWorkspaceData = serde.encode("json", newWorkspaceData, true)
fs.writeFile(workspaceFilePath, encodedWorkspaceData)

return collisionGroupData