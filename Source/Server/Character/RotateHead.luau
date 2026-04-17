local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsBadNumber = require(ReplicatedStorage.Shared.Util.IsBadNumber)

local storedItems: {Instance} = {}
local storedCharacters: {Instance} = {}

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
		item.Destroying:Connect(function()
			rotateJoint(character, "RightShoulder", 0)
			rotateJoint(character, "LeftShoulder", 0)

			table.remove(storedItems, assert(table.find(storedItems, item)))
		end)
	end
end

ReplicatedStorage.Remotes.ClientServer.RotateHead.OnServerEvent:Connect(function(plr, y: unknown)
	local char = plr.Character
	if not char or char:GetAttribute("IsRagdolled") then
		return
	end

	if typeof(y) ~= "number" or IsBadNumber(y) then
		return
	end

	y = math.clamp(y, -1.4, 1.4)

	rotateJoint(char, "Neck", y)

	if not table.find(storedCharacters, char) then
		char.ChildAdded:Connect(function(item)
			if item.Name ~= "Item" then
				return
			end

			local neck = char:FindFirstChild("Neck", true)
			if neck and neck:IsA("AnimationConstraint") and neck.Attachment0 then
				rotateForItem(char, item, (neck.Attachment0.CFrame:ToEulerAnglesXYZ()))
			end
		end)
	end

	local item = char:FindFirstChild("Item")
	if not item then
		return
	end

	rotateForItem(char, item, y)
end)

return nil