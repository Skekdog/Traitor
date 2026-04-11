local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local Types = require(ReplicatedStorage.API.Types)

local NotificationSound = Audio.MakeSound({
	Name = "NotificationSound",
	Content = Content.fromAssetId(123350827153183),
	Volume = 0.4,
})

NotificationSound.Parent = ReplicatedStorage.Assets.Gamemode.Framed

local function FramedNotification(to: Types.Participant, message: string): ()
	to.Round:SendMessage(to.Player, message, "Team")
	Audio.Play2D(NotificationSound, nil, nil, to.Player)
end

return FramedNotification