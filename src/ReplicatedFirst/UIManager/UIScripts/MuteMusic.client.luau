local UIManager = require(script.Parent.Parent)
local SoundService = game:GetService("SoundService")

local button = (UIManager.WaitForUI("Highlights").Object :: typeof(UIManager.UnregisteredUIs.Highlights)).Page.Highlights.Music.Mute 

local pause = false
button.MouseButton1Click:Connect(function()
	pause = not pause
	SoundService.RoundEndMusic.Volume = if pause then 0 else 1
	button.Image = `"rbxasset://textures/StudioToolbox/AssetPreview/{if pause then "pause" else "play"}_button.png`
end)