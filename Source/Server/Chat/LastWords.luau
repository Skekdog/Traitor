local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local GetParticipant = require(ReplicatedStorage.API.GetParticipant)

local MAX_LENGTH = 200

local remote = ReplicatedStorage.Remotes.ClientServer.LastWords

remote.OnServerEvent:Connect(function(player, lastWords: unknown): ()
	if typeof(lastWords) ~= "string" then
		return
	end

	lastWords = lastWords:sub(1, MAX_LENGTH)

	local participant = GetParticipant(player.Name)
	if not participant or participant:IsAlive() or participant:HasCorpseIcon("Last Words") then
		return
	end

	local result = TextService:FilterStringAsync(lastWords, player.UserId, Enum.TextFilterContext.PublicChat)

	participant:AddCorpseIcon({
		Name = "Last Words",
		Description = "Something tells you that this spy was about to say: " .. result:GetNonChatStringForBroadcastAsync(),
		Icon = "rbxassetid://87874288021572",
	})
end)

return nil