local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local FreeInput = require(ReplicatedStorage.FreeInput)
local LocalCharacter = require(ReplicatedStorage.LocalCharacter)

local module = {}

local SPEED = 1

local isEnabled = false

local function tryMove(dt: number): ()
	if not isEnabled then
		return
	end

	local char = LocalCharacter.GetCharacter()
	if not char then
		return
	end

	local currentPosition = char:GetPivot().Position
	local lookVector = workspace.CurrentCamera.CFrame.LookVector

	local movement = FreeInput.GetVelocity(dt)
	local newCFrame = CFrame.new(currentPosition, currentPosition + lookVector) * CFrame.new(movement * SPEED)

	char:PivotTo(newCFrame)
end

local function trySetupCharacter(): ()
	local root = LocalCharacter.GetRootPart()
	local hum = LocalCharacter.GetHumanoid()

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
	isEnabled = if enabled == nil then not isEnabled else enabled
	trySetupCharacter()

	if isEnabled then
		FreeInput.StartCapture()
	else
		FreeInput.StopCapture()
	end

	return isEnabled
end

return module