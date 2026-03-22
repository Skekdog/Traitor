local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Face = require(script.Parent.Face)

local TargetsClient = {}

TargetsClient.UI = ReplicatedStorage.Assets.Gamemode.Framed.UI.TargetChecker
TargetsClient.UI.Parent = Players.LocalPlayer.PlayerGui :: any

local currentTarget: string?
local hasIntel = false

function TargetsClient.SetCurrentTarget(target: string): ()
	currentTarget = target
end

function TargetsClient.SetIntel(has: boolean): ()
	hasIntel = has
end

function TargetsClient.GetCurrentTarget(): string?
	return currentTarget
end

function TargetsClient.GetIntel(): boolean
	return hasIntel
end

function TargetsClient.Set(): ()
	if not currentTarget then
		return
	end

	local char = workspace.Characters:FindFirstChild(currentTarget)
	if not char or not char:IsA("Model") then
		return
	end

	local label = TargetsClient.UI.ImageLabel
	label.Visible = false

	local vp = TargetsClient.UI.Viewport
	vp.Visible = false

	if hasIntel then
		local model = vp.WorldModel:FindFirstChildOfClass("Model")
		if model then
			model:Destroy()
		end

		char.Archivable = true
		char = char:Clone()
		char:PivotTo(CFrame.new(0, 0, 0))
		for _, v in char:GetChildren() do
			if v:IsA("LuaSourceContainer") or v:IsA("Model") or v.Name == "Item" then
				v:Destroy()
			end
		end

		local neck = char:FindFirstChild("Neck", true)
		if neck and neck:IsA("Motor6D") then
			neck.C0 = CFrame.new(neck.C0.Position)
		end

		char.Parent = vp.WorldModel

		local root = char:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			return
		end

		local camera = vp:FindFirstChildOfClass("Camera") or Instance.new("Camera")
		camera.CFrame = CFrame.new(Vector3.new(-1.5, 0, -4)) * CFrame.Angles(0, math.rad(-160), 0)
		camera.Parent = vp
		vp.CurrentCamera = camera
		vp.Visible = true

		return
	end

	local head = char:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end

	local face = Face.GetInstance(head)
	if not face then
		return
	end

	label.Visible = true
	label.Image = face.Image
	label.BackgroundColor3 = head.Color
end

workspace.CurrentCamera.DescendantAdded:Connect(function(descendant)
	local item = descendant:FindFirstAncestor("Item")
	if item and descendant.Name == "Screen" and item:FindFirstChild("TargetChecker") then
		TargetsClient.UI.Adornee = descendant
	end
end)

return table.freeze(TargetsClient)