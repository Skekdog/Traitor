local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
ReplicatedStorage.RoundRule.Remotes.RoundEndMusic.OnClientEvent:Connect(function(music: Sound, startedAt: number): ()
	music = music:Clone()

	music.SoundGroup = SoundService.RoundEndMusic

	music.TimePosition = workspace:GetServerTimeNow() - startedAt

	music.Ended:Once(function()
		music:Destroy()
	end)

	music.Parent = SoundService.RoundEndMusic

	music:Resume()
end)

return nil