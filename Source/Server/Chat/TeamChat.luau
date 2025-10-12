local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Types = require(ReplicatedStorage.API.Types)

local TeamChat = {}

local channels: {[Types.RoleDefinition]: TextChannel?} = {}

function TeamChat.TryAssign(participant: Types.Participant): ()
	local role = participant:GetRole()

	for definition, channel in channels do
		assert(channel)
		if definition == role.Definition then
			return
		end

		for _, user in channel:GetChildren() do
			if user:IsA("TextSource") and user.UserId == participant.Player.UserId then
				user:Destroy()
				break
			end
		end
	end

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

return TeamChat