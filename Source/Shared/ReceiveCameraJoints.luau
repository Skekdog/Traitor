local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)

local storedItems: {Instance} = {}
local storedCharacters: {Instance} = {}

local cameraRemote = GetRemote("CameraJoints", ReplicatedStorage.Remotes.ServerClient)
local recoilRemote = GetRemote("RecoilJoints", ReplicatedStorage.Remotes.ServerClient)

local TWEEN_INFO = TweenInfo.new(0.05, Enum.EasingStyle.Linear)

local function rotateJoint(character: Model, jointName: "Neck" | "RightShoulder" | "LeftShoulder", angle: number, additive: boolean?): ()
	local joint = character:FindFirstChild(jointName, true)
	if joint and joint:IsA("AnimationConstraint") and joint.Attachment0 then
		local angles = CFrame.Angles(angle, 0, 0)
		TweenService:Create(joint.Attachment0, TWEEN_INFO, {
			CFrame = if additive then joint.Attachment0.CFrame * angles else CFrame.new(joint.Attachment0.Position) * angles
		}):Play()
	end
end

local function rotateForItem(character: Model, item: Instance, angle: number, additive: boolean?, noStore: boolean?): ()
	rotateJoint(character, "RightShoulder", angle, additive)

	if item:GetAttribute("IsTwoHanded") then
		rotateJoint(character, "LeftShoulder", angle, additive)
	end

	if not noStore and not table.find(storedItems, item) then
		table.insert(storedItems, item)
		item.Destroying:Once(function()
			rotateJoint(character, "RightShoulder", 0)
			rotateJoint(character, "LeftShoulder", 0)

			table.remove(storedItems, assert(table.find(storedItems, item)))
		end)
	end
end

local function cameraTilt(character: Model, angle: number): ()
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
end

local function recoilTilt(character: Model, angle: number): ()
	local item = character:FindFirstChild("Item")
	if not item then
		return
	end

	rotateForItem(character, item, angle, true, true)
end

cameraRemote.OnClientEvent:Connect(cameraTilt)

recoilRemote.OnClientEvent:Connect(recoilTilt)

return nil