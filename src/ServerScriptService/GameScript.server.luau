local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local ActionItems = require(script.Parent.ActionItems)
local Elimination = require(script.Parent.Gamemodes.Elimination)
local ThoseYouTrust = require(script.Parent.Gamemodes.ThoseYouTrust)
local GetRound = require(script.Parent.GetRound)
local ProfileManager = require(script.Parent.ProfileManager)
local InventoryManager = require(ReplicatedFirst.InventoryManager)
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

slayVote.OnServerEvent:Connect(function(plr, target: unknown)
	if typeof(target) ~= "Instance" then
		return
	end
	if target.ClassName ~= "Player" then
		return
	end

	local round = GetRound()
	if not round then
		return
	end
	
	local voterParticipant = round:GetParticipant(plr.Name)
	local targetParticipant = round:GetParticipant(target.Name)
	if voterParticipant and targetParticipant then
		targetParticipant:TryAddSlayVote(voterParticipant)
	end
end)

local gamemodes = {ThoseYouTrust, ThoseYouTrust, ThoseYouTrust, Elimination}

remotes.GetCorpseInfo.OnServerEvent:Connect(function(plr, target: unknown)
	local round = GetRound()
	if not round or typeof(target) ~= "string" then
		return
	end

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

remotes.PurchaseEquipment.OnServerInvoke = function(plr: Player, equipmentName: any?)
	if not equipmentName then
		return
	end

	local round = GetRound()
	if not round then
		return "NoRound"
	end

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

remotes.SearchCorpse.OnServerInvoke = function(plr: Player, corpse: any?)
	if (typeof(corpse) ~= "Instance" or not corpse:IsA("Model") or not corpse:IsDescendantOf(workspace.Corpses)) and (typeof(corpse) ~= "string") then
		return
	end

	local round = GetRound()
	if not round then
		return
	end
	local participant = round:GetParticipant(plr.Name)

	local corpseParticipant: Types.Participant?
	for _, v in round.Participants do
		if v.Player.Name == corpse or v.Character == corpse then
			corpseParticipant = v
			break
		end
	end

	if not corpseParticipant then
		return
	end

	if not participant or not plr.Character then
		return corpseParticipant:ViewCorpse()
	end

	if typeof(corpse) == "string" then
		if not table.find(corpseParticipant.SearchedBy, participant) then
			return
		end
		return corpseParticipant:ViewCorpse()
	end

	if plr:DistanceFromCharacter(corpse:GetPivot().Position) > 10 then
		return
	end

	participant:SearchCorpse(corpseParticipant)

	corpse:SetAttribute("Unidentified", nil)
	return corpseParticipant:ViewCorpse()
end

local nextRoundReady = true
local nextMap = ServerStorage.Maps["Mesa Monocraft"] :: Types.MapStructureCast

local function sendRoundInfo(plr: Player?)
	local round = GetRound()
	if not round then
		return
	end

	local gm = round.Gamemode

	if plr then
		remotes.UpdateEquipment:FireClient(plr, gm.AvailableEquipment)
		remotes.UpdateRoles:FireClient(plr, gm.Name, gm.Roles)
		remotes.UpdateRoundEndInfo:FireClient(plr, round.RoundEndInfo)
		for _, v in round.Participants do
			UpdateRoundInfo.UpdateParticipantForPlayer(v, plr)
		end
		return
	end
	remotes.UpdateEquipment:FireAllClients(gm.AvailableEquipment)
	remotes.UpdateRoles:FireAllClients(gm.Name, gm.Roles)
	remotes.UpdateRoundEndInfo:FireAllClients(round.RoundEndInfo)
end

local stopMusic: (() -> ())?
joinRound.OnServerInvoke = function(plr)
	local round = GetRound()

	local initialise, gamemode
	if not round then
		if not nextRoundReady then
			return
		end
		gamemode = gamemodes[math.random(1, #gamemodes)]
		round = RoundHandler.CreateRound(nextMap, gamemode)
		initialise = true
	end

	assert(round)

	if initialise then
		if stopMusic then
			stopMusic()
		end
		
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
				voteCon = voteMap.OnServerEvent:Connect(function(plr, map: unknown)
					if typeof(map) ~= "string" or not ServerStorage.Maps:FindFirstChild(map) then
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
				assert(round.RoundEndInfo)
				remotes.UpdateRoundEndInfo:FireAllClients(round.RoundEndInfo)
				local sound = round.RoundEndInfo.Music
				if not sound then
					return
				end
				sound = sound:Clone()
				sound.SoundGroup = SoundService.RoundEndMusic
				sound.PlayOnRemove = false

				local targetVolume = sound.Volume
				sound.Volume = 0
				
				local fadeIn = TweenService:Create(sound, TweenInfo.new(1), {Volume = targetVolume})
				local fadeOut = TweenService:Create(sound, TweenInfo.new(1), {Volume = 0})

				stopMusic = function()
					fadeOut.Completed:Once(function()
						sound:Destroy()
					end)
					fadeOut:Play()
				end

				assert(stopMusic)
				if not sound:GetAttribute("FullSong") then
					if sound.TimeLength <= 0 then
						sound:GetPropertyChangedSignal("TimeLength"):Once(function()
							task.delay(sound.TimeLength - 1, stopMusic)
						end)
					else
						task.delay(sound.TimeLength - 1, stopMusic)
					end
				else
					sound.Ended:Once(stopMusic)
				end

				for _, v in round.Participants do
					local total = 0
					for _, score in v.Score do
						total += score
					end

					local plr = v.Player
					plr:SetAttribute("Score", plr:GetAttribute("Score") :: number + total)
					plr:SetAttribute("TotalScore", plr:GetAttribute("TotalScore") :: number + total)

					local profile = ProfileManager.GetProfile(plr)
					if not profile then
						continue
					end

					ProfileManager.UpdateProfile(plr, "TotalPoints", profile.TotalPoints + total)

					UpdateRoundInfo.UpdateParticipant(v)
				end

				sound.Parent = sound.SoundGroup
				sound:Play()
				fadeIn:Play()
			end
			remotes:SetAttribute("IsPaused", false)
			remotes:SetAttribute("RoundPhase", phase)
			remotes:SetAttribute("TimeMilestone", round.TimeMilestone)
		
			if phase ~= "Destroy" then
				return
			end

			InventoryManager.Reset()
			ActionItems.ResetCounters()
			workspace.Projectiles:ClearAllChildren()

			for _, v in round.Participants do
				v.Role = RoundHandler.NoRole
				UpdateRoundInfo.UpdateParticipant(v, true)
			end
		
			if voteCon then
				remotes.VoteMap:FireAllClients(false)
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
	end

	assert(round)
	
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