local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)

local MirrorUI = script.Parent.MirrorUI

MirrorUI.Parent = Players.LocalPlayer.PlayerGui :: any

local function set(face: Decal, head: BasePart): ()
	MirrorUI.ImageLabel.Image = face.Texture
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

	local face = head:WaitForChild("face")
	assert(face:IsA("Decal"))

	set(face, head)
	face:GetPropertyChangedSignal("Texture"):Connect(function()
		set(face, head)
	end)
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