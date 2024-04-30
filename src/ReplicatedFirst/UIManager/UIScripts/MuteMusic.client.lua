local button = require((game:GetService("ReplicatedFirst") :: any).UIManager).WaitForUI("Highlights").UI.Page.Highlights.Music.Mute
local SoundService = game:GetService("SoundService")
button.MouseButton1Click:Connect(function()
	local prev = SoundService.RoundEndMusic.Volume
	if prev == 0 then
		SoundService.RoundEndMusic.Volume = 1
		button.Image = "rbxasset://textures/StudioToolbox/AssetPreview/pause_button.png"
	else
		SoundService.RoundEndMusic.Volume = 0
		button.Image = "rbxasset://textures/StudioToolbox/AssetPreview/play_button.png"
	end
end)