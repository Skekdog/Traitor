local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Face = require(script.Parent.Face)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)

local MirrorUI = script.Parent.MirrorUI

MirrorUI.Parent = Players.LocalPlayer.PlayerGui :: any

local function set(face: Face.FaceInstance, head: BasePart): ()
	if face:IsA("ImageLabel") then
		face.ImageTransparency = 1
	end

	MirrorUI.ImageLabel.Image = Face.GetInstance(head).Image
	if MirrorUI.Adornee then
		assert(MirrorUI.Adornee:IsA("BasePart"))
		MirrorUI.Adornee.Color = head.Color
	end
end

local adorneeCon: RBXScriptConnection?
LocalCharacter.Head:Connect(function(head)
	if not head then
		return
	end

	local face = Face.GetInstance(head)
	if not face then
		return
	end

	set(face, head)
	if face:IsA("ImageLabel") then
		face:GetPropertyChangedSignal("Image"):Connect(function()
			set(face, head)
		end)
	elseif face:IsA("Decal") then
		face:GetPropertyChangedSignal("Texture"):Connect(function()
			set(face, head)
		end)
	end
	head:GetPropertyChangedSignal("Color"):Connect(function()
		set(face, head)
	end)

	if adorneeCon then
		adorneeCon:Disconnect()
	end
	adorneeCon = MirrorUI:GetPropertyChangedSignal("Adornee"):Connect(function()
		if MirrorUI.Adornee then
			set(face, head)
		end
	end)
end, true)

workspace.CurrentCamera.DescendantAdded:Connect(function(descendant)
	local item = descendant:FindFirstAncestor("Item")
	if item and descendant.Name == "MirrorPartFramed" then
		MirrorUI.Adornee = descendant
	end
end)

return nil