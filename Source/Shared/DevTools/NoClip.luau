local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local FreeInput = require(ReplicatedStorage.Shared.Controls.FreeInput)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)

local module = {}

local SPEED = 1

module.IsEnabled = false

local function tryMove(dt: number): ()
	if not module.IsEnabled then
		return
	end

	local char = LocalCharacter.Character()
	if not char then
		return
	end

	local currentPosition = char:GetPivot().Position
	local lookVector = workspace.CurrentCamera.CFrame.LookVector

	local movement = FreeInput.GetVelocity(dt)
	local newCFrame = CFrame.new(currentPosition, currentPosition + lookVector) * CFrame.new(movement * SPEED)

	char:PivotTo(newCFrame)
end

local function trySetupCharacter(root: BasePart, hum: Humanoid): ()
	if not root or not hum then
		return
	end

	root.Anchored = module.IsEnabled
	hum.PlatformStand = module.IsEnabled

	if not module.IsEnabled then
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

RunService.PreSimulation:Connect(tryMove)

function module.Enable(enabled: boolean?): boolean
	if module.IsEnabled == enabled then
		return module.IsEnabled
	end

	local root = LocalCharacter.RootPart()
	local hum = LocalCharacter.Humanoid()
	if not root or not hum then
		return false
	end

	module.IsEnabled = if enabled == nil then not module.IsEnabled else enabled
	trySetupCharacter(root, hum)

	if module.IsEnabled then
		FreeInput.StartCapture()
	else
		FreeInput.StopCapture()
	end

	if not module.IsEnabled then
		hum:ChangeState(Enum.HumanoidStateType.Running)
		task.delay(0, hum.ChangeState, hum, Enum.HumanoidStateType.Freefall)
	end

	return module.IsEnabled
end

Players.LocalPlayer.CharacterRemoving:Connect(function()
	module.Enable(false)
end)

return module