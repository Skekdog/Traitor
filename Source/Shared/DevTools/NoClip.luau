local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local FreeInput = require(ReplicatedStorage.Shared.Controls.FreeInput)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)

local module = {}

local SPEED = 1

local isEnabled = false

function module.IsEnabled(): boolean
	return isEnabled
end

local function tryMove(dt: number): ()
	if not isEnabled then
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

	root.Anchored = isEnabled
	hum.PlatformStand = isEnabled

	if not isEnabled then
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

RunService.PreSimulation:Connect(tryMove)

function module.Enable(enabled: boolean?): boolean
	if isEnabled == enabled then
		return isEnabled
	end

	local root = LocalCharacter.RootPart()
	local hum = LocalCharacter.Humanoid()
	if not root or not hum then
		return false
	end

	isEnabled = if enabled == nil then not isEnabled else enabled
	trySetupCharacter(root, hum)

	if isEnabled then
		FreeInput.StartCapture()
	else
		FreeInput.StopCapture()
	end

	if not isEnabled then
		hum:ChangeState(Enum.HumanoidStateType.Running)
		task.delay(0, hum.ChangeState, hum, Enum.HumanoidStateType.Freefall)
	end

	return isEnabled
end

Players.LocalPlayer.CharacterRemoving:Connect(function()
	module.Enable(false)
end)

return table.freeze(module)