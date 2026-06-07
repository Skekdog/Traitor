local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Badge = require(ReplicatedStorage.Shared.Monetisation.Badge)
local BadgeIDs = require(ReplicatedStorage.Shared.Monetisation.BadgeIDs)

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
		local roles: {IsMember: boolean, Roles: {{Id: number, Name: string, Rank: number}}} = GroupService:GetRolesInGroupAsync(player.UserId, game.CreatorId)
		for _, role in roles.Roles do
			if role.Name ~= "Guest" and role.Name ~= "Member" then
				table.insert(tags, role.Name)
			end
		end
	end)

	if result then
		warn(result)
	end

	if Badge.IsOwned(BadgeIDs["Tester Town"], player) then
		table.insert(tags, "Alpha Tester")
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

return table.freeze(ChatTags)