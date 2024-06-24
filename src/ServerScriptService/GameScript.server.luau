local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local InventoryManager = require(script.Parent.Parent.ReplicatedFirst.InventoryManager)
local UpdateRoundInfo = require(script.Parent.UpdateRoundInfo)
local Types = require(ReplicatedFirst.RoundHandler.Types)
local RoundHandler = require(ReplicatedFirst.RoundHandler.RoundHandler)

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

slayVote.OnServerEvent:Connect(function(plr, target: Player?)
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
		local gm = require(v) :: Types.Gamemode
		table.insert(gamemodes, gm)
	end
end

remotes.GetCorpseInfo.OnServerEvent:Connect(function(plr, target: string?)
	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId or not target then
		return
	end

	local round = RoundHandler.GetRound(roundId)
	local targetParticipant = round:GetParticipant(target)
	local participant = round:GetParticipant(plr.Name)

	if not targetParticipant or not participant then
		return
	end

	if not table.find(targetParticipant.SearchedBy, participant) then
		return
	end

	remotes.SendCorpseInfo:FireClient(plr, targetParticipant:ViewCorpse())
end)

remotes.PurchaseEquipment.OnServerInvoke = function(plr: Player, equipmentName: string?)
	if not equipmentName then
		return
	end

	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then
		return "NoRound"
	end

	local round = RoundHandler.GetRound(roundId)
	local participant = round:GetParticipant(plr.Name)
	if not participant then
		return "NotInRound"
	end

	local equipment = round:GetEquipment(equipmentName)
	if not equipment then
		return "NotFound"
	end
	
	return participant:PurchaseEquipment(equipment)
end

local nextRoundReady = true
local nextMap = ServerStorage.Maps["Mesa Monocraft"] :: Types.MapStructureCast

local function sendRoundInfo(plr: Player?)
	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then
		return
	end

	local round = RoundHandler.GetRound(roundId)
	local gm = round.Gamemode

	if plr then
		remotes.UpdateEquipment:FireClient(plr, gm.AvailableEquipment)
		remotes.UpdateRoles:FireClient(plr, gm.Name, gm.Roles)
		for _, v in round.Participants do
			UpdateRoundInfo.UpdateParticipantForPlayer(v, plr)
		end
		return
	end
	remotes.UpdateEquipment:FireAllClients(gm.AvailableEquipment)
	remotes.UpdateRoles:FireAllClients(gm.Name, gm.Roles)
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
		local votes: {[string]: {number}} = {}
		local voteCon: RBXScriptConnection?

		nextRoundReady = false

		 -- Ordering of these 4 attributes matters, as MapAuthors is what the client listens to.
		remotes:SetAttribute("MapName", nextMap.Name)
		remotes:SetAttribute("MapAuthors", (nextMap:FindFirstChild("Authors") and nextMap.Authors or {Value = "unknown"}).Value)

		remotes:SetAttribute("GamemodeName", gamemode.Name)
		remotes:SetAttribute("GamemodeAuthors", gamemode.Authors or "unknown")
		remotes:SetAttribute("TimeMilestone", round.TimeMilestone)
		remotes.MapFolder.Value = round.Map :: Types.MapStructureCast

		sendRoundInfo()

		local roundEventCon: RBXScriptConnection

		local function roundPhaseChange(phase: Types.RoundPhase)
			if phase == "Playing" then
				remotes:SetAttribute("RoundStartTime", workspace:GetServerTimeNow())
				for _, v in round.Participants do
					UpdateRoundInfo.UpdateParticipant(v)
				end
			elseif phase == "Intermission" then
				voteMap:FireAllClients(true)
				voteCon = voteMap.OnServerEvent:Connect(function(plr, map: string?)
					if not map or not ServerStorage.Maps:FindFirstChild(map) then
						return
					end

					for _, v in votes do
						if table.find(v, plr.UserId) then
							table.remove(v, table.find(v, plr.UserId))
							break
						end
					end

					if not votes[map] then
						votes[map] = {plr.UserId}
					else
						table.insert(votes[map], plr.UserId)
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

			InventoryManager.ClearAllItems()

			for _, v in round.Participants do
				v._status = "Spectating" :: any
				v.Role = RoundHandler.NoRole
				UpdateRoundInfo.UpdateParticipant(v)
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
				local maps = ServerStorage.Maps:GetChildren()
				Random.new():Shuffle(maps)
				nextMap = (ServerStorage.Maps:FindFirstChild(bestMap) :: Types.MapStructureCast) or (maps[1] :: Types.MapStructureCast)
			end
		
			roundEventCon:Disconnect()
			ServerStorage:SetAttribute("RoundID", nil)
			nextRoundReady = true
		end

		roundPhaseChange("Waiting")
		roundEventCon = round.RoundPhaseChangeEvent.Event:Connect(roundPhaseChange)
	else
		round = RoundHandler.GetRound(roundId)
	end
	
	if not round:GetParticipant(plr.Name) then
		local participant = round:JoinRound(plr)
		participant.CreditsChanged.Event:Connect(UpdateRoundInfo.UpdateOwnParticipant)
		participant.StatusChanged.Event:Connect(function()
			UpdateRoundInfo.UpdateParticipant(participant)
		end)
		UpdateRoundInfo.UpdateParticipant(participant)
		return true
	end
	return
end

Players.PlayerAdded:Connect(sendRoundInfo)