local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local FilterDead = require(script.Parent.FilterDead)
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local QuickChat = require(ReplicatedStorage.Shared.Interface.Chat.QuickChat.QuickChat)
local Replication = require(ReplicatedStorage.Shared.RoundRule.Replication)

local remote = GetRemote("QuickChat", ReplicatedStorage.Remotes)

local rateLimits: {[Player]: number?} = {}

-- Stupidly high, but Roblox requires it /shrug
-- https://create.roblox.com/docs/chat/preset-system-guidelines#requirements
local RATE_LIMIT_INTERVAL = 10

remote.OnServerEvent:Connect(function(player: Player, messageId: unknown, id: unknown): ()
	if typeof(messageId) ~= "number" then
		return
	end

	if typeof(id) ~= "nil" and (typeof(id) ~= "Instance" or not id:IsA("Model")) then
		return
	end

	local baseMessage = QuickChat.Messages[messageId]
	if not baseMessage then
		return
	end

	if (rateLimits[player] or 0) + RATE_LIMIT_INTERVAL > os.clock() then
		return Replication.SendMessage(player, "Please do not flood the chat.", "Chat")
	end

	rateLimits[player] = os.clock()

	local formattedMessage = QuickChat.FormatMessage(baseMessage, id)

	task.spawn(function()
		-- https://devforum.roblox.com/t/-/4539685/302
		-- According to this post, this step is only needed for "visibility into messages".
		-- Additionally, it claims that this can be done once on load (it can't, as a user id is required).
		-- Therefore, we make the call to filter it, but ignore the result, because we know its safe.
		-- To be honest, all of these requirements are insanely bullshit, but whatever.
		TextService:FilterStringAsync(formattedMessage, player.UserId, Enum.TextFilterContext.PublicChat)
	end)

	for _, v in Players:GetPlayers() do
		if FilterDead.ShouldSend(player, v) then
			ReplicatedStorage.Shared.RoundRule.Remotes.SendMessage:FireClient(v, formattedMessage, "QuickChat", player)
		end
	end
end)

return nil