local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Types = require(ReplicatedFirst.RoundHandler.Types)
local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local API = require(ReplicatedFirst.API)
local UIManager = require(ReplicatedFirst.UIManager)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)
local joinRound = UIManager.WaitForUI("JoinRound")

local vote = UIManager.WaitForUI("VotingScreen") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.VotingScreen)}
for _, v in ReplicatedStorage.RoundHandler.GetMaps:InvokeServer() do
	local clone = vote.Object.Sample:Clone()
	clone.Text = v
	clone.Visible = true
	clone.Name = v
	clone.Parent = vote.Object.Choices :: any

    clone.MouseButton1Click:Connect(function()
        ReplicatedStorage.RoundHandler.VoteMap:FireServer(v)
    end)
end

local stopMusic: (() -> ())?
local ownParticipant: Types.ClientOwnParticipant?
local ownRole: Types.Role?

LocalRoundInfo.Listen("UpdateOwnParticipant", function(p)
    local participant = p :: Types.ClientOwnParticipant?
    ownParticipant = participant
    if ownParticipant then
        ownRole = LocalRoundInfo.GetRole(ownParticipant.Role)
    else
        ownRole = nil
    end
end)

local function highlight(participant)
    local clone = Instance.new("Highlight")
    CollectionService:AddTag(clone, "AllyMarker")
    clone.FillTransparency = 1
    clone.OutlineColor = LocalRoundInfo.GetRole(participant.Role).Colour
    clone.OutlineTransparency = 0
    clone.Parent = participant.Player.Character
end

LocalRoundInfo.Listen("UpdateParticipant", function(p)
    local participant = p :: Types.ClientParticipant?
    if not participant then
        return
    end

    print(ownRole, p)

    if ownRole and ownRole.HighlightRoles then
        local allRoles = table.find(ownRole.HighlightRoles, "__All")
        if allRoles then
            highlight(participant)
        else
            if table.find(ownRole.HighlightRoles, participant.Role:split("__")[2]) then
                highlight(participant)
            elseif table.find(ownRole.HighlightRoles, "__Ally") and table.find(ownRole.Allies or {}, participant.Role:split("__")[2]) then
                highlight(participant)
            elseif table.find(ownRole.HighlightRoles, "__Enemy") and not table.find(ownRole.Allies or {}, participant.Role:split("__")[2]) then
                highlight(participant)
            end
        end
    end
end)

type EquipmentShopType = UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs["Equipment Shop"])}
local equipmentShop: EquipmentShopType?
local function update(roundPhase)
    if roundPhase == "Destroy" then
        joinRound:ToggleVisible(true)

        for _, v in CollectionService:GetTagged("AllyMarker") do
            v:Destroy()
        end

        for _, v in Players:GetPlayers() do
            v:SetAttribute("Mark", "")
            v:SetAttribute("Searched", false)
        end

        if equipmentShop then
            equipmentShop:Unregister()
            equipmentShop = nil
        end

        ReplicatedFirst.ClientStorage:SetAttribute("IsSpectating", false)

        return
    end

    if not ownParticipant or not Players.LocalPlayer.Character then
        ReplicatedFirst.ClientStorage:SetAttribute("IsSpectating", true)
    end

    if stopMusic and roundPhase ~= "Intermission" then
        stopMusic()
    end

    joinRound:ToggleVisible((roundPhase == "Waiting") or (roundPhase == "Preparing"))
    
    if roundPhase == "Highlights" then
        local endInfo = LocalRoundInfo.GetRoundEndInfo()
        assert(endInfo)
        local sound = endInfo.Music
        if not sound then
            return
        end
        sound = sound:Clone()
        sound.SoundGroup = SoundService.RoundEndMusic
        sound.Volume = 0
        
        local fadeIn = TweenService:Create(sound, TweenInfo.new(1), {Volume = 0.5})
        local fadeOut = TweenService:Create(sound, TweenInfo.new(1), {Volume = 0})

        sound.Parent = SoundService.RoundEndMusic
        sound:Play()

        local highlights = UIManager.WaitForUI("Highlights").Object :: typeof(UIManager.UnregisteredUIs.Highlights)
        highlights.Page.Highlights.Music.Text.Text = sound.Name
        
        fadeIn:Play()

        stopMusic = function()
            stopMusic = nil
            if not sound or not sound.Parent then
                return
            end
            fadeOut:Play()
            task.delay(1, function()
                sound:Stop()
                sound:Destroy()
                sound = nil
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
			roundInfo.TopBar.Timer.Text = "PAUSED"
		else
			roundInfo.TopBar.Timer.Text = lastTime
		end
		return
	end

	roundInfo.TopBar.Timer.Text = API.ToRoundTime(time, timeTarget)
end

task.spawn(function()
    while true do
        updateTimer(workspace:GetServerTimeNow())
        task.wait()
    end
end)

LocalRoundInfo.Listen("TimeMilestone", function(time)
    timeTarget = time :: number
end)

LocalRoundInfo.Listen("IsPaused", function(isPaused)
    lastTime = roundInfo.TopBar.Timer.Text
    paused = isPaused :: boolean
end)

LocalRoundInfo.Listen("UpdateOwnParticipant", function(p)
    local participant = p :: Types.ClientOwnParticipant

    local role
    if participant then
        role = LocalRoundInfo.GetRole(participant.Role)
    end
    if not participant or role.Name == "" then
        roundInfo.TopBar.Role.TextColor3 = Color3.new(1, 1, 1)
        roundInfo.TopBar.Role.Text = if LocalRoundInfo.GetRoundPhase() == "Destroy" then "SPECTATING" else "PREPARING"
        return
    end

    roundInfo.TopBar.Role.Text = role.Name
    roundInfo.TopBar.Role.TextColor3 = role.Colour

    local toRegister = UIManager.UnregisteredUIs:FindFirstChild("Equipment Shop")
    if not role.EquipmentShop or #role.EquipmentShop <= 0 or not toRegister then
        return
    end

    local shop
    if equipmentShop then
        shop = equipmentShop.Object
    else
        equipmentShop = UIManager.RegisterUI(toRegister) :: EquipmentShopType
        assert(equipmentShop)
        shop = equipmentShop.Object
    end
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
update(LocalRoundInfo.GetRoundPhase())