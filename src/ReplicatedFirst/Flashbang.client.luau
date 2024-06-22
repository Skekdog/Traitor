local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local tweenStart = TweenInfo.new(0.15)
local tweenFinish = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 4)

local equaliser = Instance.new("EqualizerSoundEffect")
equaliser.Name = "FlashbangEffect"
equaliser.HighGain = -8
equaliser.LowGain = 10
equaliser.MidGain = -20
equaliser.Enabled = true

(ReplicatedStorage:WaitForChild("ServerClient") :: typeof(ReplicatedStorage.ServerClient)).Flashbang.OnClientEvent:Connect(function()
	local correction = Instance.new("ColorCorrectionEffect")
	local blur = Instance.new("BlurEffect")
	
	correction.Name = "FlashbangCorrection"
	blur.Name = "FlashbangBlur"
	
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

	local ring = Instance.new("Sound")
	ring.SoundId = "rbxassetid://223471024"
	ring.Volume = 2
	ring.PlayOnRemove = true
	ring.Parent = SoundService
	ring:Destroy()
end)