local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local RoundHandlerTypes = require(script.Parent.RoundHandlerTypes)
local RoundHandler = require(script.Parent.RoundHandler)

local remotes: any = ReplicatedStorage:FindFirstChild("RoundHandler")
local slayVote = remotes.SlayVote
local getPartialParticipants = remotes.GetPartialParticipants
local getPartialParticipant = remotes.GetPartialParticipant
local roundPhaseChange = remotes.RoundPhaseChange
local getPartialRound = remotes.GetPartialRound
local getOwnInfo = remotes.GetOwnInfo
local joinRound = remotes.JoinRound
local getMaps = remotes.GetMaps

local function getMinimalParticipant(participant: RoundHandlerTypes.Participant): RoundHandlerTypes.PartialParticipant
	return {
		Player = participant.Player,
		Status = participant.Status
	}
end

getMaps.OnServerInvoke = function()
	local names = {}
	for _, v in ServerStorage.Maps:GetChildren() do
		table.insert(names, v.Name)
	end
	return names
end

getPartialParticipants.OnServerInvoke = function(plr)
	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then return {} end

	local round = RoundHandler.GetRound(roundId)
	local self = round:TryGetParticipant(plr.Name)

	local participants = {}
	if not self then
		for _, v in round.Participants do
			table.insert(participants, getMinimalParticipant(v))
		end
	else
		for _, v in round.Participants do
			table.insert(participants, self:ViewPartialParticipant(v))
		end
	end

	return participants
end

getPartialParticipant.OnServerInvoke = function(plr, targetName: string)
	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then return end

	local round = RoundHandler.GetRound(roundId)
	local self = round:TryGetParticipant(plr.Name)
	local target = round:TryGetParticipant(targetName)

	if self and target then
		return self:ViewPartialParticipant(target)
	elseif not target then
		return
	end

	return getMinimalParticipant(target)
end

getOwnInfo.OnServerInvoke = function(plr): RoundHandlerTypes.PartialParticipant?
	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then return end

	local p = RoundHandler.GetRound(roundId):GetParticipant(plr.Name)
	if not p then
		return
	end

	local a = p:ViewPartialParticipant(p)
	a.Credits = p.Credits
	return a
end

getPartialRound.OnServerInvoke = function(plr)
	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then
		return
	end

	return RoundHandler.GetRound(roundId):GetPartialRound()
end

slayVote.OnServerEvent:Connect(function(plr, target: Player)
	local roundId = ServerStorage:GetAttribute("RoundID")
	if (not roundId) or (typeof(target) ~= "Instance")  then
		return
	end
	if target.ClassName ~= "Player" then
		return
	end

	local round = RoundHandler.GetRound(roundId)
	local voterParticipant = round:TryGetParticipant(plr.Name)
	local targetParticipant = round:TryGetParticipant(target.Name)
	if voterParticipant and targetParticipant then
		targetParticipant:TryAddSlayVote(voterParticipant)
	end
end)

local gamemodes = {}
for _, v in script.Parent.Gamemodes:GetChildren() do
	if v.Name == "ThoseYouTrust" then
		local gm = require(v) :: any
		table.insert(gamemodes, gm)
	end
end

local nextRoundReady = true
local nextMap = "Mesa Monocraft"

joinRound.OnServerInvoke = function(plr)
	local round: RoundHandlerTypes.Round
	local roundId = ServerStorage:GetAttribute("RoundID")

	if not nextRoundReady then
		return
	end

	if not roundId then
		round = RoundHandler.CreateRound(ServerStorage.Maps[nextMap], gamemodes[math.random(1, #gamemodes)])
		ServerStorage:SetAttribute("RoundID", round.ID)
		round.RoundPhaseChangeEvent.Event:Connect(function(phase)
			roundPhaseChange:FireAllClients(phase)
			if phase ~= "Intermission" then
				return
			end

			nextRoundReady = false
			ServerStorage:SetAttribute("RoundID", nil)
		end)
	else
		round = RoundHandler.GetRound(roundId)
	end
	
	if not round:GetParticipant(plr.Name) then
		round:JoinRound(plr)
		return true
	end
	return
end