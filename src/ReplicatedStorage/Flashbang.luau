local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local PlaySound = require(ReplicatedStorage.RoundRule.Common.PlaySound)

local tweenStart = TweenInfo.new(0.15)
local tweenFinish = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 4)

local equaliser = Instance.new("EqualizerSoundEffect")
equaliser.Name = "FlashbangEffect"
equaliser.HighGain = -8
equaliser.LowGain = 10
equaliser.MidGain = -20
equaliser.Enabled = true

return function()
    local correction = Instance.new("ColorCorrectionEffect")
	local blur = Instance.new("BlurEffect")
	
	correction.Name = "FlashbangCorrection"
	blur.Name = "FlashbangBlur"

	correction:SetAttribute("IgnoreLighting", true)
	blur:SetAttribute("IgnoreLighting", true)
	
	blur.Parent = Lighting
	correction.Parent = Lighting
	
	local equaliser = equaliser:Clone()
	equaliser.Parent = SoundService:FindFirstChild("AllSounds")
	
	local tween = TweenService:Create(correction, tweenStart, {Brightness = 0.8})
	tween.Completed:Once(function()
		local endTween = TweenService:Create(correction, tweenFinish, {Brightness = 0})
		endTween.Completed:Once(function()
			blur:Destroy()
			correction:Destroy()
			equaliser:Destroy()
		end)
		endTween:Play()
		TweenService:Create(blur, tweenFinish, {Size = 0}):Play()
	end)
	tween:Play()
	TweenService:Create(blur, tweenStart, {Size = 48}):Play()

	PlaySound("rbxassetid://223471024", nil, nil)
end
