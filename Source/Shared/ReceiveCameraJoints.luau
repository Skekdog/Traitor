local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = require(ReplicatedStorage.API.GetRemote)

local storedItems: {Instance} = {}
local storedCharacters: {Instance} = {}

local remote = GetRemote("CameraJoints", ReplicatedStorage.Remotes)

local function rotateJoint(character: Model, jointName: "Neck" | "RightShoulder" | "LeftShoulder", angle: number): ()
	local joint = character:FindFirstChild(jointName, true)
	if joint and joint:IsA("AnimationConstraint") and joint.Attachment0 then
		joint.Attachment0.CFrame = CFrame.new(joint.Attachment0.Position) * CFrame.Angles(angle, 0, 0)
	end
end

local function rotateForItem(character: Model, item: Instance, angle: number): ()
	rotateJoint(character, "RightShoulder", angle)

	if item:GetAttribute("IsTwoHanded") then
		rotateJoint(character, "LeftShoulder", angle)
	end

	if not table.find(storedItems, item) then
		table.insert(storedItems, item)
		item.Destroying:Once(function()
			rotateJoint(character, "RightShoulder", 0)
			rotateJoint(character, "LeftShoulder", 0)

			table.remove(storedItems, assert(table.find(storedItems, item)))
		end)
	end
end

remote.OnClientEvent:Connect(function(character: Model, angle: number): ()
	rotateJoint(character, "Neck", angle)

	if not table.find(storedCharacters, character) then
		table.insert(storedCharacters, character)
		character.ChildAdded:Connect(function(item)
			if item.Name ~= "Item" then
				return
			end

			local neck = character:FindFirstChild("Neck", true)
			if neck and neck:IsA("AnimationConstraint") and neck.Attachment0 then
				rotateForItem(character, item, (neck.Attachment0.CFrame:ToEulerAnglesXYZ()))
			end
		end)

		character.Destroying:Once(function()
			table.remove(storedCharacters, assert(table.find(storedCharacters, character)))
		end)
	end

	local item = character:FindFirstChild("Item")
	if not item then
		return
	end

	rotateForItem(character, item, angle)
end)

return nil