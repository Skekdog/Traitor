local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local IsSubmerged = require(ReplicatedStorage.Shared.Character.IsSubmerged)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local GetTaggedDescendants = require(ReplicatedStorage.Shared.RoundRule.Common.GetTaggedDescendants)

local TINT_COLOUR = Color3.fromRGB(171, 223, 255)
local CONTRAST = 0.1
local BRIGHTNESS = -0.1
local BLUR_SIZE = 12

local colourCorrection = Instance.new("ColorCorrectionEffect")
colourCorrection:SetAttribute("IgnoreLighting", true)
colourCorrection.Parent = Lighting

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur:SetAttribute("IgnoreLighting", true)
blur.Parent = Lighting

local TWEEN_INFO = TweenInfo.new(0.15)

local colourCorrectionActivate = TweenService:Create(colourCorrection, TWEEN_INFO, {
	TintColor = TINT_COLOUR,
	Contrast = CONTRAST,
	Brightness = BRIGHTNESS,
})

local blurActivate = TweenService:Create(blur, TWEEN_INFO, {
	Size = BLUR_SIZE,
})

local colourCorrectionDeactivate = TweenService:Create(colourCorrection, TWEEN_INFO, {
	TintColor = Color3.new(1, 1, 1),
	Contrast = 0,
	Brightness = 0,
})

local blurDeactivate = TweenService:Create(blur, TWEEN_INFO, {
	Size = 0,
})

local isActive = false
local function activateEffects(): ()
	if isActive then
		return
	end

	isActive = true

	colourCorrectionActivate:Play()
	blurActivate:Play()
end

local function deactivateEffects(): ()
	if not isActive then
		return
	end

	isActive = false

	colourCorrectionDeactivate:Play()
	blurDeactivate:Play()
end

local params = RaycastParams.new()
params.IgnoreWater = false
params.FilterType = Enum.RaycastFilterType.Include
params.CollisionGroup = "PlayerCharacterParts" -- so that we include bounds

RunService.PostSimulation:Connect(function()
	local humanoid = LocalCharacter.Humanoid()
	if not humanoid then
		deactivateEffects()
		return
	end

	local head = LocalCharacter.Head()
	if not head then
		return
	end

	local map = LocalRoundInfo.Map()
	if not map or not map.Structure:IsDescendantOf(workspace) then
		deactivateEffects()
		return
	end

	local include = GetTaggedDescendants(map.Structure, "Water")
	table.insert(include, workspace.Terrain)
	params.FilterDescendantsInstances = include

	if IsSubmerged(humanoid, head.Position, params) then
		activateEffects()
	else
		deactivateEffects()
	end
end)

return nil