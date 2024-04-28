local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Types = require(ReplicatedFirst.RoundHandlerTypes)
local SettingsManager = require(ReplicatedFirst.SettingsManager)
local UIManager = require(ReplicatedFirst.UIManager)

local remotes = ReplicatedStorage.RoundHandler

local roundInfo = UIManager.WaitForUI("RoundInfo").UI
local joinRound = UIManager.WaitForUI("JoinRound")

local timeTarget = 0
local paused = false
local lastTime = ""
local function updateTimer()
    if paused then
		if os.time()%2 == 1 then --Alternate every second
			roundInfo.Timer.Text = "PAUSED"
		else
			roundInfo.Timer.Text = lastTime
		end
		return
	end

	local minutes = tostring(math.floor(timeTarget / 60))
	local seconds = tostring(math.fmod(timeTarget, 60))

	if string.len(minutes) < 2 then
		minutes = "0"..minutes
	end
	if string.len(seconds) < 2 then
		seconds = "0"..seconds
	end

	roundInfo.Timer.Text = minutes..":"..seconds
end

local vote = UIManager.WaitForUI("VotingScreen")
for _, v in ReplicatedStorage.RoundHandler.GetMaps:InvokeServer() do
	local clone = vote.UI:FindFirstChild("Sample"):Clone()
	clone.Text = v
	clone.Visible = true
	clone.Name = v
	clone.Parent = vote.UI:FindFirstChild("Choices")

    clone.MouseButton1Click:Connect(function()
        ReplicatedStorage.RoundHandler.VoteMap:FireServer(v)
    end)
end

local stopMusic: (() -> ())?

local lastTimerThread: thread?
local function update(round: (Types.PartialRound & {Role: Types.Role})?)
    if lastTimerThread then
        task.cancel(lastTimerThread)
    end

    round = round or ReplicatedStorage.RoundHandler.GetPartialRound:InvokeServer()
    if not round then
        -- Allow for creation of a new round
        joinRound:ToggleVisible(true)

        for _, v in CollectionService:GetTagged("AllyMarker") do
            v:Destroy()
        end

        for _,v in Players:GetPlayers() do
            v:SetAttribute("Mark", "")
            v:SetAttribute("Searched", false)
        end

        UIManager.UnregisterUI("Equipment Shop","UserTriggered")

        return
    end

    (game :: any):FindFirstChild("ClientStorage").CurrentMapObject.Value = round.Map

    if stopMusic then
        stopMusic()
    end

    joinRound:ToggleVisible((round.RoundPhase == "Waiting") or (round.RoundPhase == "Preparing"))

    timeTarget = round.TimeMilestone
    lastTimerThread = task.spawn(function()
        while workspace:GetServerTimeNow() < round.TimeMilestone do
            updateTimer()
            task.wait(1)
        end
    end)

    if round.RoundPhase == "Playing" then
        if #round.Role.EquipmentShop > 0 then
            local shop = UIManager.RegisterUI("Equipment Shop", "UserTriggered", false, ReplicatedFirst.UIManager.UnregisteredUIs.UserTriggered["Equipment Shop"], "Shop", false).UI
            shop.PurchaseEquipment.Reset:Fire()

            local nameToObj = {}
            for _, e in round.Gamemode.AvailableEquipment do
                nameToObj[e.Name] = e
            end

            for _,v in round.Role.EquipmentShop do
                local equipment = nameToObj[v]
                
                local entry = shop.Entry:Clone()
                entry:SetAttribute("CreditCost", equipment.Cost)
                entry:SetAttribute("Description", equipment.Description)
                
                entry.Image = equipment.Icon
                entry.Name = equipment.Name
                entry.Visible = true
                entry.Parent = shop.ScrollingFrame
            end
        end

        local participants: {Types.PartialParticipant} = remotes.GetPartialParticipants:InvokeServer()

        local roleHighlights = {}

        for _, role in round.Gamemode.Roles do
            local thisRelation = table.find(role.Allies, round.Role.Name) and "__Ally" or "__Enemy"
            local verdict
            for relation, highlight in round.Role.HighlightRules do
                if relation == role.Name then
                    verdict = highlight
                    break
                elseif verdict == nil then
                    verdict = if relation == "__All" then highlight else thisRelation == relation
                end
            end
            roleHighlights[role.Name] = verdict
        end

        for _, v in participants do
            if not v.Role then
                continue
            end
            if roleHighlights[v.Role.Name] then
                local clone = Instance.new("Highlight")
                CollectionService:AddTag(clone, "AllyMarker")
                clone.FillTransparency = 1
                clone.OutlineColor = v.Role.Colour
                clone.OutlineTransparency = 0
                clone.Parent = v.Player.Character
            end
        end
    elseif round.RoundPhase == "Waiting" then
        if SettingsManager.GetSetting("Use FIB Lighting") then
            local mapConfig = round.Map:WaitForChild("FIBLighting", 3)
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
    elseif round.RoundPhase == "Highlights" then
        assert(round.RoundEndInfo and round.RoundEndInfo.Winners.VictoryMusic)
        local sound = Instance.new("Sound")
        sound.SoundGroup = SoundService.RoundEndMusic
        sound.Volume = 0
        
        local fadeIn = TweenService:Create(sound,TweenInfo.new(1),{Volume = 0.5})
        local fadeOut = TweenService:Create(sound,TweenInfo.new(1),{Volume = 0})
        
        sound.SoundId = round.RoundEndInfo.Winners.VictoryMusic[1].SoundId
        sound.Name = round.RoundEndInfo.Winners.VictoryMusic[1].Name

        sound.Parent = SoundService.RoundEndMusic
        sound:Play()
        
        fadeIn:Play()

        stopMusic = function()
            if not sound then
                return
            end
            fadeOut:Play()
            task.delay(1, function()
                sound:Stop()
                sound:Destroy()
            end)
        end
        
        if not sound:GetAttribute("FullSong") then
            if sound.TimeLength > 0 then
                task.delay(sound.TimeLength-1, stopMusic :: any)
            else
                sound:GetPropertyChangedSignal("TimeLength"):Connect(task.delay, sound.TimeLength-1, stopMusic)
            end
        end
    end
end

ReplicatedStorage.RoundHandler.VoteMap.OnClientEvent:Connect(function(allow)
    vote:ToggleVisible(allow)
end)

ReplicatedStorage.RoundHandler.RoundPause.OnClientEvent:Connect(function(pausedOrResumeTime: true | number)
    if pausedOrResumeTime == true then
        lastTime = roundInfo.Timer.Text
        paused = true
        return
    end
    timeTarget = pausedOrResumeTime
end)

ReplicatedStorage.RoundHandler.RoundPhaseChange.OnClientEvent:Connect(update)

update()