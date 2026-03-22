local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Types = require(ReplicatedStorage.API.Types)

local TeamChat = {}

local channels: {[Types.RoleDefinition]: TextChannel?} = {}

function TeamChat.TryRemove(id: number): ()
	for definition, channel in channels do
		assert(channel)
		for _, user in channel:GetChildren() do
			if user:IsA("TextSource") and user.UserId == id then
				user:Destroy()
				break
			end
		end
	end
end

function TeamChat.TryAssign(participant: Types.Participant): ()
	local role = participant:GetRole()
	TeamChat.TryRemove(participant.Player.UserId)

	if not role.Definition.CanTeamChat then
		return
	end

	local channel = channels[role.Definition]
	if not channel then
		local newChannel = Instance.new("TextChannel")
		newChannel.Name = "Team_" .. role.Definition.Name
		newChannel.Parent = TextChatService:WaitForChild("TextChannels")
		channels[role.Definition] = newChannel
		channel = newChannel
	end
	assert(channel)

	local source: TextSource? = channel:AddUserAsync(participant.Player.UserId)
	if not source then
		return
	end

	source.CanSend = true
end

function TeamChat.Clear(): ()
	for _, channel in channels do
		assert(channel)
		channel:Destroy()
	end
	channels = {}
end

return table.freeze(TeamChat)