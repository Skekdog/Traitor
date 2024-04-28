local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local RoundHandler = require(script.Parent.RoundHandler)

local remotes: any = ReplicatedStorage:FindFirstChild("RoundHandler")
local slayVote = remotes.SlayVote
local getPartialParticipants = remotes.GetPartialParticipants
local getPartialRound = remotes.GetPartialRound

getPartialParticipants.OnServerInvoke = function(plr)
	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then
		return
	end

	local round = RoundHandler.GetRound(roundId)
	local self = round:GetParticipant(plr.Name)

	local participants = {}
	for _, v in round.Participants do
		table.insert(participants, self:ViewPartialParticipant(v))
	end

	return participants
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

ReplicatedStorage.ClientServer.JoinRound.OnServerEvent:Connect(function(plr)
	local round
	local roundId = ServerStorage:GetAttribute("RoundID")
	if (not roundId) then
		round = RoundHandler.CreateRound((ServerStorage :: any).Maps["Mesa Monocraft"], gamemodes[math.random(1, #gamemodes)])
		round.RoundEndEvent.Event:Once(function()
			ServerStorage:SetAttribute("RoundID", nil)
		end)
	else
		round = RoundHandler.GetRound(roundId)
	end
	
	if not round:TryGetParticipant(plr.Name) then
		round:JoinRound(plr)
	end
end)