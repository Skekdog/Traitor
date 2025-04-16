local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

ReplicatedStorage.RoundRule.Remotes.RoundEndMusic.OnClientEvent:Connect(function(music: Sound, startedAt: number): ()
	music = music:Clone()

	local targetVolume = music.Volume

	music.SoundGroup = SoundService.RoundEndMusic

	music.Volume = 0
	music.TimePosition = workspace:GetServerTimeNow() - startedAt

	music.Ended:Once(function()
		music:Destroy()
	end)

	music.Parent = SoundService.RoundEndMusic

	music:Resume()

	TweenService:Create(music, TweenInfo.new(1), {
		Volume = targetVolume,
	}):Play()
end)

return nil