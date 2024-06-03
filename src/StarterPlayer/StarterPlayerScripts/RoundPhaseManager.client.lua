local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local API = require(ReplicatedFirst.API)
local Types = require(ReplicatedFirst.RoundHandler.Types)
local SettingsManager = require(ReplicatedFirst.SettingsManager)
local UIManager = require(ReplicatedFirst.UIManager)

local roundInfo = UIManager.WaitForUI("RoundInfo").UI :: any
local joinRound = UIManager.WaitForUI("JoinRound")

local vote: UIManager.UI & {UI: typeof(ReplicatedFirst.UIManager.UnregisteredUIs.Popup.VotingScreen)} = UIManager.WaitForUI("VotingScreen")
for _, v in ReplicatedStorage.RoundHandler.GetMaps:InvokeServer() do
	local clone = vote.UI.Sample:Clone()
	clone.Text = v
	clone.Visible = true
	clone.Name = v
	clone.Parent = vote.UI.Choices :: any

    clone.MouseButton1Click:Connect(function()
        ReplicatedStorage.RoundHandler.VoteMap:FireServer(v)
    end)
end

local stopMusic: (() -> ())?

local function update()
    local roundPhase = LocalRoundInfo.GetRoundPhase()
    local participant: Types.Participant? = LocalRoundInfo.GetOwnParticipant()
    local ownRole: Types.Role?
    if participant then
        ownRole = participant.Role
    end

    if roundPhase == "Destroy" then
        -- Allow for creation of a new round
        joinRound:ToggleVisible(true)

        for _, v in CollectionService:GetTagged("AllyMarker") do
            v:Destroy()
        end

        for _, v in Players:GetPlayers() do
            v:SetAttribute("Mark", "")
            v:SetAttribute("Searched", false)
        end

        UIManager.UnregisterUI("Equipment Shop", "UserTriggered")

        return
    end

    if stopMusic and roundPhase ~= "Intermission" then
        stopMusic()
    end

    joinRound:ToggleVisible((roundPhase == "Waiting") or (roundPhase == "Preparing"))

    if roundPhase == "Playing" then
        ReplicatedFirst.ClientStorage:SetAttribute("RoundStartTime", workspace:GetServerTimeNow()) --todo: this can probably cause problems under big lag
        if ownRole then
            local participants: {Types.PartialParticipant} = LocalRoundInfo.GetAllParticipants()

            if ownRole.HighlightRules then
                local roleHighlights = {}

                local roles: {Types.Role} = LocalRoundInfo.GetAllRoles() or {}
                for _, role in roles do
                    local thisRelation = table.find(role.Allies or {}, ownRole.Name) and "__Ally" or "__Enemy"
                    local verdict
                    for relation, highlight in ownRole.HighlightRules do
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
            end
        end
    elseif roundPhase == "Waiting" then
        if SettingsManager.GetSetting("Use FIB Lighting") then
            local map = LocalRoundInfo.GetMap()
            if not map then
                return
            end
            local mapConfig = map:WaitForChild("FIBLighting", 3)
            if mapConfig then
                for _, prop in mapConfig:GetChildren() do
                    if prop:IsA("ValueBase") then
                        if (Lighting :: any)[prop.Name] then
                            (Lighting :: any)[prop.Name] = (prop :: any).Value
                        end
                    end
                end
            else
                print("FIB Lighting settings were not found for "..roundInfo.MapName)
            end
        end
    elseif roundPhase == "Highlights" then
        local endInfo = LocalRoundInfo.GetRoundEndInfo()
        assert(endInfo)
        local sound = endInfo.Music
        if not sound then
            return
        end
        sound.SoundGroup = SoundService.RoundEndMusic
        sound.Volume = 0
        
        local fadeIn = TweenService:Create(sound, TweenInfo.new(1), {Volume = 0.5})
        local fadeOut = TweenService:Create(sound, TweenInfo.new(1), {Volume = 0})

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
            assert(stopMusic)
            if sound.TimeLength > 0 then
                task.delay(sound.TimeLength-1, stopMusic)
            else
                sound:GetPropertyChangedSignal("TimeLength"):Connect(function()
                    task.delay(sound.TimeLength-1, stopMusic)
                end)
            end
        end
    end
end

ReplicatedStorage.RoundHandler.VoteMap.OnClientEvent:Connect(function(allow)
    vote:ToggleVisible(allow)
end)

local timeTarget = 0
local paused = false
local lastTime = ""
local function updateTimer(time: number)
    if paused then
		if math.round(time) % 2 == 1 then --Alternate every second
			roundInfo.Timer.Text = "PAUSED"
		else
			roundInfo.Timer.Text = lastTime
		end
		return
	end

	roundInfo.Timer.Text = API.ToRoundTime(time, timeTarget)
end

task.spawn(function()
    while true do
        updateTimer(workspace:GetServerTimeNow())
        task.wait()
    end
end)

LocalRoundInfo.Listen("TimeMilestone", function(time)
    timeTarget = time
end)

LocalRoundInfo.Listen("IsPaused", function(isPaused)
    lastTime = roundInfo.Timer.Text
    paused = isPaused
end)

LocalRoundInfo.Listen("UpdateOwnParticipant", function(participant: Types.Participant?)
    if not participant or participant.Role.Name == "" then
        roundInfo.Frame.Role.TextColor3 = Color3.new(1, 1, 1)
        roundInfo.Frame.Role.Text = if LocalRoundInfo.GetRoundPhase() == "Destroy" then "SPECTATING" else "PREPARING"
        return
    end

    local role = participant.Role
    roundInfo.Frame.Role.Text = role.Name
    roundInfo.Frame.Role.TextColor3 = role.Colour

    local toRegister = ReplicatedFirst.UIManager.UnregisteredUIs.UserTriggered:FindFirstChild("Equipment Shop")
    if not role.EquipmentShop or #role.EquipmentShop <= 0 or not toRegister then
        return
    end

    local shop: typeof(toRegister) = UIManager.RegisterUI("Equipment Shop", "UserTriggered", false, toRegister, "Shop", false).UI
    shop.Reset:Fire()
    
    for _, v in shop.ScrollingFrame:GetChildren() do
        if v.ClassName == "ImageButton" then
            v:Destroy()
        end
    end

    local nameToObj = {}
    local availableEquipment = LocalRoundInfo.GetAllEquipment()
    if availableEquipment then
        for _, e in availableEquipment do
            nameToObj[e.Name] = e
        end
    end

    for _, v in role.EquipmentShop do
        local equipment = nameToObj[v]
        
        local entry = shop.EquipmentEntry:Clone()
        entry:SetAttribute("CreditCost", equipment.Cost)
        entry:SetAttribute("Description", equipment.Description)
        
        entry.BackgroundTransparency = 0
        entry.Image = equipment.Icon
        entry.Name = equipment.Name
        entry.Visible = true
        entry.Parent = shop.ScrollingFrame :: any
    end
end)

LocalRoundInfo.Listen("RoundPhase", update)
update()