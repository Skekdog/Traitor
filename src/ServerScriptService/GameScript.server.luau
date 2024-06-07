local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local UpdateRoundInfo = require(script.Parent.UpdateRoundInfo)
local Types = require(ReplicatedFirst.RoundHandler.Types)
local RoundHandler = require(ReplicatedFirst.RoundHandler.RoundHandler) :: Types.ServerRoundHandler

local remotes = ReplicatedStorage.RoundHandler
local slayVote = remotes.SlayVote
local joinRound = remotes.JoinRound
local getMaps = remotes.GetMaps
local voteMap = remotes.VoteMap

getMaps.OnServerInvoke = function()
	local names = {}
	for _, v in ServerStorage.Maps:GetChildren() do
		table.insert(names, v.Name)
	end
	return names
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
	local voterParticipant = round:GetParticipant(plr.Name)
	local targetParticipant = round:GetParticipant(target.Name)
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
local nextMap = ServerStorage.Maps["Mesa Monocraft"] :: Types.MapStructure

local function sendRoundInfo(plr: Player?)
	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then
		return
	end

	local round = RoundHandler.GetRound(roundId)
	local gm = round.Gamemode

	if plr then
		remotes.UpdateEquipment:FireClient(plr, gm.AvailableEquipment)
		remotes.UpdateRoles:FireClient(plr, gm.Roles)
		UpdateRoundInfo.SendUpdatedParticipants(round.Participants, round:GetParticipant(plr.Name) ,plr)
		return
	end
	remotes.UpdateEquipment:FireAllClients(gm.AvailableEquipment)
	remotes.UpdateRoles:FireAllClients(gm.Roles)
end

joinRound.OnServerInvoke = function(plr)
	local round: Types.Round
	local roundId = ServerStorage:GetAttribute("RoundID")

	if not roundId then
		if not nextRoundReady then
			return
		end
		local gamemode = gamemodes[math.random(1, #gamemodes)]
		round = RoundHandler.CreateRound(nextMap, gamemode)
		ServerStorage:SetAttribute("RoundID", round.ID)
		local votes = {}
		local voteCon: RBXScriptConnection?

		nextRoundReady = false

		 -- Ordering of these 4 attributes matters, as MapAuthors is what the client listens to.
		remotes:SetAttribute("MapName", nextMap.Name)
		remotes:SetAttribute("MapAuthors", (nextMap:FindFirstChild("Authors") and nextMap.Authors or {Value = "unknown"}).Value)

		remotes:SetAttribute("GamemodeName", gamemode.Name)
		remotes:SetAttribute("GamemodeAuthors", gamemode.Authors or "unknown")
		remotes:SetAttribute("TimeMilestone", round.TimeMilestone)
		remotes.MapFolder.Value = round.Map

		sendRoundInfo()

		local roundEventCon: RBXScriptConnection
		roundEventCon = round.RoundPhaseChangeEvent.Event:Connect(function(phase)
			if phase == "Playing" then
				remotes:SetAttribute("RoundStartTime", workspace:GetServerTimeNow())
				for _, v in Players:GetPlayers() do
					UpdateRoundInfo.SendUpdatedParticipants(round.Participants, round:GetParticipant(v.Name), v)
				end
			elseif phase == "Intermission" then
				voteMap:FireAllClients(true)
				voteCon = voteMap.OnServerEvent:Connect(function(plr, map: string)
					if not ServerStorage.Maps:FindFirstChild(map) then
						return
					end
					if not votes[map] then
						votes[map] = {plr}
					elseif not table.find(votes[map], plr) then
						table.insert(votes[map], plr)
					end
				end)
			elseif phase == "Highlights" then
				remotes.UpdateRoundEndInfo:FireAllClients(round.RoundEndInfo)
			end
			remotes:SetAttribute("IsPaused", false)
			remotes:SetAttribute("RoundPhase", phase)
			remotes:SetAttribute("TimeMilestone", round.TimeMilestone)

			if phase ~= "Destroy" then
				return
			end

			for _, v in round.Participants do
				v.Status = "Spectating" :: any
			end

			for _, v in Players:GetPlayers() do
				local p = round:GetParticipant(v.Name)
				if p then
					p.Role = {
						Name = "",
						Colour = Color3.new()
					}
				end
				UpdateRoundInfo.SendUpdatedParticipants(round.Participants, p, plr)
			end

			if voteCon then
				ReplicatedStorage.RoundHandler.VoteMap:FireAllClients(false)
				voteCon:Disconnect()
				local bestMap, bestVotes = "", 0
				for i, v in votes do
					if #v > bestVotes then
						bestMap = i
						bestVotes = #v
					end
				end
				nextMap = (ServerStorage.Maps:FindFirstChild(bestMap) :: Types.MapStructure) or (ServerStorage.Maps:GetChildren()[math.random(1, #ServerStorage.Maps:GetChildren())] :: Types.MapStructure)
			end

			roundEventCon:Disconnect()
			ServerStorage:SetAttribute("RoundID", nil)
			nextRoundReady = true
		end)
	else
		round = RoundHandler.GetRound(roundId)
	end
	
	if not round:GetParticipant(plr.Name) then
		local participant: any = table.clone(round:JoinRound(plr)) -- Might be worth doing a "client-safe" type for these sorts of things - no cyclic tables, no methods, no other "unsafe" fields
		participant.Round = nil -- This is a shallow copy, all is fine
		remotes.UpdateOwnParticipant:FireClient(plr, participant)
		return true
	end
	return
end

Players.PlayerAdded:Connect(sendRoundInfo)