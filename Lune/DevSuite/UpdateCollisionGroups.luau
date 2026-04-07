local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Base64 = require("@lib/Base64")

local UNSAFE_DATA_LENGTH = 20

local function UpdateCollisionGroups(inputFile: string): ()
	local projectData = fs.readFile("build.project.json")
	local project = serde.decode("json", projectData)

	local tree = project.tree or error("Missing tree in project file")
	local projectWorkspace = tree.Workspace or error("Missing Workspace in project file")
	local workspacePath = projectWorkspace["$path"] or error("Missing $path in Workspace")

	local workspaceFilePath = workspacePath .. "/init.meta.json"
	if not fs.isFile(workspaceFilePath) then
		error("Missing Workspace init.meta.json")
	end

	local workspaceData = serde.decode("json", fs.readFile(workspaceFilePath))

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

	print("Updated collision group data!")
end

return UpdateCollisionGroups