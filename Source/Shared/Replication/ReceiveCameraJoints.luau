local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)

local storedItems: {Instance} = {}
local storedCharacters: {Instance} = {}

local cameraRemote = GetRemote("CameraJoints", ReplicatedStorage.Remotes.ServerClient)
local recoilRemote = GetRemote("RecoilJoints", ReplicatedStorage.Remotes.ServerClient)

local TWEEN_INFO = TweenInfo.new(0.05, Enum.EasingStyle.Linear)
local RECOIL_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Circular, Enum.EasingDirection.In, 0, true)

local function rotateJoint(character: Model, jointName: "Neck" | "RightShoulder" | "LeftShoulder", angle: number, isRecoil: boolean?): ()
	local joint = character:FindFirstChild(jointName, true)
	if joint and joint:IsA("Motor6D") then
		local angles = CFrame.Angles(angle, 0, 0)
		if isRecoil then
			joint.C1 = CFrame.new(joint.C1.Position)
			TweenService:Create(joint, RECOIL_TWEEN_INFO, {
				C1 = CFrame.new(joint.C1.Position) * angles
			}):Play()
		else
			TweenService:Create(joint, TWEEN_INFO, {
				C0 = CFrame.new(joint.C0.Position) * angles
			}):Play()
		end
	end
end

local function rotateForItem(character: Model, item: Instance, angle: number, isRecoil: boolean?, noStore: boolean?): ()
	rotateJoint(character, "RightShoulder", angle, isRecoil)

	if item:GetAttribute("IsTwoHanded") then
		rotateJoint(character, "LeftShoulder", angle, isRecoil)
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
			if neck and neck:IsA("Motor6D") then
				rotateForItem(character, item, (neck.C0:ToEulerAnglesXYZ()))
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