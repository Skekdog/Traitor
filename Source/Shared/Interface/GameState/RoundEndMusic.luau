local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)

local function fadeOut(music: Sound): ()
	local tween = TweenService:Create(music, TweenInfo.new(1), {Volume = 0})
	tween.Completed:Once(function()
		music:Destroy()
	end)
	tween:Play()
end

ReplicatedStorage.Shared.RoundRule.Remotes.RoundEndMusic.OnClientEvent:Connect(function(music: Sound, startedAt: number): ()
	music = music:Clone()

	music.SoundGroup = SoundService.RoundEndMusic

	music.TimePosition = workspace:GetServerTimeNow() - startedAt

	music.Ended:Once(function()
		music:Destroy()
	end)

	music.Parent = SoundService.RoundEndMusic

	music:Resume()
end)

LocalRoundInfo.RoundPhase:Connect(function(phase)
	if phase ~= "Preparing" then
		return
	end

	local music = SoundService.RoundEndMusic:FindFirstChildOfClass("Sound")
	if music then
		fadeOut(music)
	end
end)

return nil