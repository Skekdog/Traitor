local CS = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("SoundService")
local TS = game:GetService("TweenService")

local cs = RS.ClientServer
local sc = RS.ServerClient

local plr = Players.LocalPlayer

local settingsManager = require(game:GetService("ReplicatedFirst").SettingsManager)
uiScript = game:GetService("ReplicatedFirst").UIManager
local uiManager = require(uiScript)

local maps = RS.ClientServer.GetMaps:InvokeServer()

local gui = plr.PlayerGui
local join = uiManager.WaitForUI("JoinRound", "HUD")
local vote = uiManager.WaitForUI("VotingScreen", "Popup")
local roundInfoUi = gui:WaitForChild("HUD"):WaitForChild("RoundInfo",math.huge)

--VoteManager
local clickCons = {}
for _,v in maps do
	local clone = vote.UI:FindFirstChild("Sample"):Clone()
	clone.Text = v
	clone.Visible = true
	clone.Name = v
	clone.Parent = vote.UI:FindFirstChild("Choices")
end

local function clearMarks()
	for _,v in Players:GetPlayers() do
		v:SetAttribute("Mark","")
		v:SetAttribute("Searched",false)
	end
end

--RoundInfo
local paused = false
local lastTime = "00:00"
local endTime = 0
sc.UpdateTimer.OnClientEvent:Connect(function(round,time_t,pausedV)
	endTime = time_t
	lastTime = roundInfoUi.Timer.Text
	paused = pausedV
end)

local function updateTime(secondsRaw)
	if paused then
		if os.time()%2 == 1 then --Alternate every second
			roundInfoUi.Timer.Text = "PAUSED"
		else
			roundInfoUi.Timer.Text = lastTime
		end
		return
	end
	local minutes = tostring(math.floor(secondsRaw/60))
	local seconds = tostring(math.fmod(secondsRaw,60))

	if string.len(minutes) < 2 then
		minutes = "0"..minutes
	end
	if string.len(seconds) < 2 then
		seconds = "0"..seconds
	end

	roundInfoUi.Timer.Text = minutes..":"..seconds
end

--JoinRound
local sw = {"Starting","Waiting"}
local mainInfo = cs.GetRoundInfo:InvokeServer("Main","Round")
if mainInfo then
	join:ToggleVisible(table.find(sw,mainInfo.RoundPhase)~=nil)
else --round does not exist, allow creation of a new round
	join:ToggleVisible(true)
end

local invChangedCon
sc.RoundPhaseChange.OnClientEvent:Connect(function(phase:string,round:string,endInfo:{["Music"]:{string}})
	
	if round == "Main" and not plr:GetAttribute("InRound") then
		join:ToggleVisible(table.find(sw,phase)~=nil)
	end
	
	
	--VoteManager
	if round == plr:GetAttribute("CurrentRound") then
		vote:ToggleVisible(false)
		for i,v in clickCons do
			v:Disconnect()
		end
		clickCons = {}
	end
	
	
	local info = RS.ClientServer.GetRoundInfo:InvokeServer(round,"Self+Round+Players+PlayerRoles")
	if typeof(info) ~= "table" then return end
	
	
	local roundInfo = info.RoundInfo
	local plrs = info.Players
	local selfInfo = info.PlayerInfo
	local plrRoles = info.PlayerRoles
	
	local gamemode = roundInfo.Gamemode
	local roles = gamemode.Roles
	
	local ownRole
	if selfInfo then ownRole = roles[selfInfo.Role] end
	
	
	if --[[round == plr:GetAttribute("CurrentRound")]] true then
		
		
		--AllyMarkerManager
		for i,v in pairs(CS:GetTagged("AllyMarker")) do v:Destroy() end
		
		
		--RoundInfo
		endTime = roundInfo.RoundTime
		if endTime then
			local stop = false
			local con
			con = sc.RoundPhaseChange.OnClientEvent:Connect(function(phase:string,round:string)
				if round == plr:GetAttribute("CurrentRound") then
					paused = false
					stop = true
					con:Disconnect()
				end
			end)
			updateTime(os.difftime(endTime,workspace:GetServerTimeNow()))
			local crtn
			crtn = coroutine.create(function()
				repeat
					updateTime(os.difftime(endTime,workspace:GetServerTimeNow()))
					task.wait()
				until stop or endTime-workspace:GetServerTimeNow() <= 0
				roundInfoUi.Timer.Text = "Waiting (Timer Desynced!)"
				con:Disconnect()
				coroutine.yield(crtn)
				coroutine.close(crtn)
			end)
			coroutine.resume(crtn)
		else
			roundInfoUi.Timer.Text = "Waiting"
		end
		
		
		if phase == "Starting" then
			clearMarks()
			uiManager.UnregisterUI("EquipmentShop","UserTriggered")
		elseif phase == "Playing" then
			if ownRole then
				--AllyMarkerManager
				if ownRole.AlwaysSeeKnownAllies then
					for _,v in plrs do
						local otherRole = plrRoles[v.Name]
						if otherRole ~= "__!!Unknown" then
							if table.find(ownRole.Allies,otherRole) then
								local clone = Instance.new("Highlight")
								CS:AddTag(clone,"AllyMarker")
								clone.FillTransparency = 1
								clone.OutlineColor = roles[otherRole].Colour
								clone.OutlineTransparency = 0
								clone.Parent = v.Character
							end
						end
					end
				end
				--LoadEquipmentShop
				if #ownRole.EquipmentShop > 0 then
					local success,shop = pcall(function()return uiManager.RegisterUI("Equipment Shop","UserTriggered",false,uiScript.UnregisteredUIs.UserTriggered:FindFirstChild("Equipment Shop"),"Shop")end)
					if success then
						shop = shop.UI
						shop.PurchaseEquipment.Reset:Fire()
						local frame = shop.ScrollingFrame
						local entry = shop:WaitForChild("EquipmentEntry")
						
						for _,v in frame:GetChildren() do if v:IsA("ImageButton") then v:Destroy() end end

						for _,v in ownRole.EquipmentShop do
							local newEntry = entry:Clone()
							local equipment = gamemode.Equipment[v]
							newEntry:SetAttribute("CreditCost",equipment[2])
							newEntry:SetAttribute("Description",equipment[3])
							
							if typeof(equipment[1]) == "Instance" then
								newEntry.TextLabel.Visible = true
								newEntry.TextLabel.Text = "["..(equipment[1]:GetAttribute("Slot") or "0").."]"
								local inUse = false
								for _,v in plr.Inventory:GetChildren() do
									if v:GetAttribute("Slot") == equipment[1]:GetAttribute("Slot") then
										inUse = true
										break
									end
								end
								if inUse then newEntry.TextLabel.TextColor3 = Color3.new(1,0,0) end
							end

							newEntry.Image = "rbxassetid://"..equipment[4]
							newEntry.Visible = true

							newEntry.Name = v
							newEntry.Parent = frame
						end
						
						if invChangedCon then invChangedCon:Disconnect() end
						invChangedCon = (game :: any):WaitForChild("ClientStorage"):WaitForChild("ScriptConnections").InventoryChangedEvent.Event:Connect(function(item,added)
							if added then
								for _,v in frame:GetChildren() do
									if v:IsA("ImageButton") then
										if tonumber(v.TextLabel.Text:sub(2,2)) == item:GetAttribute("Slot") then
											v.TextLabel.TextColor3 = Color3.new(1,0,0)
										end
									end
								end
							else
								for _,v in frame:GetChildren() do
									if v:IsA("ImageButton") then
										if tonumber(v.TextLabel.Text:sub(2,2)) == item:GetAttribute("Slot") then
											v.TextLabel.TextColor3 = Color3.new(0,1,0)
										end
									end
								end
							end
						end)
					end
				end

			end
			
		elseif phase == "Highlights" then
			
			
			--VictoryMusic
			local sound = Instance.new("Sound")
			sound.SoundGroup = SS.RoundEndMusic
			sound.Volume = 0
			
			local fadeIn = TS:Create(sound,TweenInfo.new(1),{Volume = 0.5})
			local fadeOut = TS:Create(sound,TweenInfo.new(1),{Volume = 0})
			
			sound.SoundId = endInfo.Music[1]
			sound.Name = endInfo.Music[2]

			sound.Parent = SS.RoundEndMusic
			sound:Play()
			
			fadeIn:Play()
			
			if not sound:GetAttribute("FullSong") then
				sound:GetPropertyChangedSignal("TimeLength"):Connect(function()
					delay(sound.TimeLength-1,function()fadeOut:Play()end)
				end)
			end
			
			local con
			con = sc.RoundPhaseChange.OnClientEvent:Connect(function(phase,round)
				if round == plr:GetAttribute("CurrentRound") and phase == "Starting" then
					con:Disconnect()
					fadeOut:Play()
					delay(1,function()
						sound:Stop()
						sound:Destroy()
					end)
				end
			end)
			
			
		elseif phase == "Intermission" then
			clearMarks()
			if round == "Main" then plr:SetAttribute("InRound",false) end
			uiManager.UnregisterUI("Equipment Shop","UserTriggered")
			--VoteManager
			vote:ToggleVisible(true)
			for _,v in vote.UI:FindFirstChild("Choices"):GetChildren() do
				if v:IsA("TextButton") then
					table.insert(clickCons,v.MouseButton1Click:Connect(function()
						cs.VoteMap:FireServer(v.Name)
					end))
				end
			end
			
			
		elseif phase == "Waiting" then
			clearMarks()
			uiManager.UnregisterUI("Equipment Shop","UserTriggered")
			if round == "Main" and gamemode and roundInfo.MapName then
				
				if settingsManager.GetSetting("Use FIB Lighting") then
					local mapConfig = workspace:WaitForChild("__Map"):WaitForChild("FIBLighting",3)
					if mapConfig then
						for _,prop in mapConfig:GetChildren() do
							if prop:IsA("ValueBase") then
								if Lighting[prop.Name] then
									Lighting[prop.Name] = prop.Value
								end
							end
						end
					else
						print("FIB Lighting settings were not found for "..roundInfo.MapName)
					end
				end
			end
		end
	end
end)