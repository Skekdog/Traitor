local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

ReplicatedStorage.RoundRule.Remotes.RoundEndMusic.OnClientEvent:Connect(function(music: Sound, startedAt: number): ()
	local targetVolume = music.Volume

	music.SoundGroup = SoundService.RoundEndMusic

	music.Volume = 0
	music.TimePosition = workspace:GetServerTimeNow() - startedAt

	music:Resume()

	TweenService:Create(music, TweenInfo.new(1), {
		Volume = targetVolume,
	}):Play()
end)

return nil