local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChatTags = {}

local tagCache: {[Player]: {string}?} = {}

function ChatTags.GetAvailableTags(player: Player): {string}
	local tags = tagCache[player]
	if tags then
		return tags
	end

	tags = {}
	assert(tags)

	local _, result = pcall(function()
		local groupRole = player:GetRoleInGroupAsync(game.CreatorId)
		if groupRole ~= "Guest" and groupRole ~= "Member" then
			table.insert(tags, groupRole)
		end
	end)

	if result then
		warn(result)
	end

	_, result = pcall(function()
		if BadgeService:UserHasBadgeAsync(player.UserId, 2136698808) then
			table.insert(tags, "Alpha Tester")
		end
	end)

	if result then
		warn(result)
	end

	tagCache[player] = tags
	return tags
end

function ChatTags.Set(player: Player, tag: string?): ()
	player:SetAttribute("ChatTag", tag)
end

Players.PlayerRemoving:Connect(function(player)
	tagCache[player] = nil
end)

ReplicatedStorage.Remotes.ClientServer.GetChatTags.OnServerInvoke = function(player: Player): {string}
	return ChatTags.GetAvailableTags(player)
end

ReplicatedStorage.Remotes.ClientServer.SetChatTag.OnServerEvent:Connect(function(player, tag: unknown)
	if typeof(tag) ~= "string" then
		return
	end

	if tag == "None" then
		ChatTags.Set(player)
		return
	end

	if table.find(ChatTags.GetAvailableTags(player), tag) then
		ChatTags.Set(player, tag)
	end
end)

return ChatTags