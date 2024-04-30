local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local RoundHandlerTypes = require(ReplicatedFirst.RoundHandlerTypes)
local RoundHandler = require(script.Parent.RoundHandler)

local remotes: any = ReplicatedStorage:FindFirstChild("RoundHandler")
local slayVote = remotes.SlayVote
local getPartialParticipants = remotes.GetPartialParticipants
local getPartialParticipant = remotes.GetPartialParticipant
local getPartialRound = remotes.GetPartialRound
local getOwnInfo = remotes.GetOwnInfo
local joinRound = remotes.JoinRound
local voteMap = remotes.VoteMap

local function getMinimalParticipant(participant: RoundHandlerTypes.Participant): RoundHandlerTypes.PartialParticipant
	return {
		Player = participant.Player,
		Status = participant.Status
	}
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

getOwnInfo.OnServerInvoke = function(plr)
	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then return end

	return RoundHandler.GetRound(roundId):TryGetParticipant(plr.Name)
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
	local round
	local roundId = ServerStorage:GetAttribute("RoundID")

	if not nextRoundReady then
		return
	end

	if not roundId then
		round = RoundHandler.CreateRound(ServerStorage.Maps[nextMap], gamemodes[math.random(1, #gamemodes)])
		ServerStorage:SetAttribute("RoundID", round.ID)
		round.RoundEndEvent.Event:Once(function()
			nextRoundReady = false
			ServerStorage:SetAttribute("RoundID", nil)

			local votes = {}
			for _, map in ServerStorage.Maps:GetChildren() do
				votes[map.Name] = {}
			end
			local voteCon = voteMap.OnServerEvent:Connect(function(plr, map)
				if not table.find(votes[map], plr) then
					table.insert(votes[map], plr)
				end
			end)
			voteMap:FireAllClients(true)

			task.delay(10, function()
				voteMap:FireAllClients(false)
				voteCon:Disconnect()

				local chosenMap = "Mesa Monocraft"
				local highestVotes = 0
				for map, voters in votes do
					if #voters > highestVotes then
						chosenMap = map
					end
				end

				nextMap = chosenMap
				nextRoundReady = true
			end)
		end)
	else
		round = RoundHandler.GetRound(roundId)
	end
	
	if not round:TryGetParticipant(plr.Name) then
		round:JoinRound(plr)
		return true
	end
	return
end