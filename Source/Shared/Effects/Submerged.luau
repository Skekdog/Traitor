local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local IsSubmerged = require(ReplicatedStorage.Shared.Character.IsSubmerged)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local GetTaggedDescendants = require(ReplicatedStorage.Shared.RoundRule.Common.GetTaggedDescendants)

local TINT_COLOUR = Color3.fromRGB(171, 223, 255)

local CONTRAST = 0.1
local BRIGHTNESS = -0.1
local BLUR_SIZE = 12

local ATMOSPHERE_DENSITY = 0.8
local ATMOSPHERE_COLOUR = Color3.new(0.5, 0.5, 0.5)
local ATMOSPHERE_DECAY = Color3.new(1, 1, 1)
local ATMOSPHERE_OFFSET = 0
local ATMOSPHERE_GLARE = 1
local ATMOSPHERE_HAZE = 0

local colourCorrection = Instance.new("ColorCorrectionEffect")
colourCorrection:SetAttribute("IgnoreLighting", true)
colourCorrection.Parent = Lighting

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur:SetAttribute("IgnoreLighting", true)
blur.Parent = Lighting

local equaliser = Instance.new("EqualizerSoundEffect")
equaliser.HighGain = -10
equaliser.LowGain = 5
equaliser.MidGain = -5
equaliser.Enabled = false
equaliser.Parent = SoundService.AllSounds

local reverb = Instance.new("ReverbSoundEffect")
reverb.DecayTime = 0.1
reverb.Density = 1
reverb.DryLevel = -6
reverb.WetLevel = 2
reverb.Enabled = false
reverb.Parent = SoundService.AllSounds

local atmosphere: Atmosphere?

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

local function createAtmosphere(): ()
	atmosphere = Instance.new("Atmosphere")
	assert(atmosphere)

	atmosphere.Density = ATMOSPHERE_DENSITY
	atmosphere.Decay = ATMOSPHERE_DECAY
	atmosphere.Color = ATMOSPHERE_COLOUR
	atmosphere.Offset = ATMOSPHERE_OFFSET
	atmosphere.Glare = ATMOSPHERE_GLARE
	atmosphere.Haze = ATMOSPHERE_HAZE
	atmosphere.Decay = TINT_COLOUR
	atmosphere:SetAttribute("IgnoreLighting", true)

	atmosphere.Parent = Lighting
end

local function removeAtmosphere(): ()
	if atmosphere then
		atmosphere:Destroy()
		atmosphere = nil
	end
end

local isActive = false
local function activateEffects(): ()
	if isActive then
		return
	end

	isActive = true

	colourCorrectionActivate:Play()
	blurActivate:Play()

	removeAtmosphere()
	createAtmosphere()

	reverb.Enabled = true
	equaliser.Enabled = true
end

local function deactivateEffects(): ()
	if not isActive then
		return
	end

	isActive = false

	colourCorrectionDeactivate:Play()
	blurDeactivate:Play()

	removeAtmosphere()

	reverb.Enabled = false
	equaliser.Enabled = false
end

local params = RaycastParams.new()
params.IgnoreWater = false
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
	params.IncludeInstances = include

	if IsSubmerged(humanoid, head.Position, params) then
		activateEffects()
	else
		deactivateEffects()
	end
end)

return nil