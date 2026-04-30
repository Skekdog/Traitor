local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameHooks = require(ReplicatedStorage.API.GameHooks)
local GetParticipant = require(ReplicatedStorage.API.GetParticipant)
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Types = require(ReplicatedStorage.API.Types)

local TeamVoice = {}

local activeTeam: {[Player]: Types.Role?} = {}

local remote = GetRemote("TeamVoice", ReplicatedStorage.Remotes.ClientServer)

local function getAudioInput(player: Player): AudioDeviceInput?
	return player:FindFirstChildWhichIsA("AudioDeviceInput")
end

local function assignPlayers(audioInput: AudioDeviceInput, round: Types.Round, role: Types.Role): ()
	local participants = round:GetParticipantsWithRole(role)

	local userIds: {number} = {}
	for _, p in participants do
		table.insert(userIds, p.Player.UserId)
	end

	audioInput:SetUserIdAccessList(userIds)
end

function TeamVoice.Activate(player: Player): ()
	local participant = GetParticipant(player)
	if not participant then
		return
	end

	local role = participant:GetRole()
	if not role.Definition.CanTeamChat then
		return
	end

	local audioInput = getAudioInput(player)
	if not audioInput then
		return
	end

	activeTeam[player] = role

	audioInput.AccessType = Enum.AccessModifierType.Allow
	assignPlayers(audioInput, participant.Round, role)
end

function TeamVoice.Deactivate(player: Player): ()
	activeTeam[player] = nil

	local audioInput = getAudioInput(player)
	if not audioInput then
		return
	end

	audioInput.AccessType = Enum.AccessModifierType.Deny
	audioInput:SetUserIdAccessList({})
end

local function OnRoleAssigned(round: Types.Round, participant: Types.Participant, role: Types.Role)
	local player = participant.Player

	local oldRole = activeTeam[player]
	if not oldRole then
		return
	end

	-- This removes participant from their team chats
	for _, p in round:GetParticipantsWithRole(oldRole) do
		local audioInput = getAudioInput(p.Player)
		if audioInput and activeTeam[p.Player] then
			assignPlayers(audioInput, round, oldRole)
		end
	end

	if not role.Definition.CanTeamChat then
		return TeamVoice.Deactivate(player)
	end

	local audioInput = getAudioInput(player)
	if audioInput then
		-- And this sets participant's new team chats
		assignPlayers(audioInput, round, role)
	end
end

Players.PlayerRemoving:Connect(function(player)
	activeTeam[player] = nil
end)

GameHooks.OnRoleAssigned["TeamVoice"] = OnRoleAssigned

local function OnDeath(_, participant: Types.Participant): ()
	TeamVoice.Deactivate(participant.Player)
end

GameHooks.OnDeath["TeamVoice"] = OnDeath

remote.OnServerEvent:Connect(function(player: Player, active: unknown)
	if typeof(active) ~= "boolean" then
		return
	end

	if active then
		TeamVoice.Activate(player)
	else
		TeamVoice.Deactivate(player)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		local player = Players:FindFirstChildWhichIsA("Player")
		if not player then
			continue
		end
		local input = getAudioInput(player)
		if input then
			print(#input:GetUserIdAccessList())
		end
	end
end)

return table.freeze(TeamVoice)