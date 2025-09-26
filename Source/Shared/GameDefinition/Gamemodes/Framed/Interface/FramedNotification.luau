local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Types = require(ReplicatedStorage.API.Types)

local function FramedNotification(to: Types.Participant, message: string): ()
	to.Round:SendMessage(to.Player, message, "Team")
	PlaySound(123350827153183, nil, nil, {Volume = 0.4}, to.Player)
end

return FramedNotification