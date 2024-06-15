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

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(ReplicatedFirst.UIManager.UnregisteredUIs.RoundInfo)
local joinRound = UIManager.WaitForUI("JoinRound")

local vote = UIManager.WaitForUI("VotingScreen") :: UIManager.UI & {Object: typeof(ReplicatedFirst.UIManager.UnregisteredUIs.VotingScreen)}
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

type EquipmentShopType = UIManager.UI & {Object: typeof(ReplicatedFirst.UIManager.UnregisteredUIs["Equipment Shop"])}
local equipmentShop: EquipmentShopType?
local function update(roundPhase)
    local participant: Types.ClientOwnParticipant? = LocalRoundInfo.GetOwnParticipant()
    local ownRole: Types.Role?
    if participant then
        ownRole = LocalRoundInfo.GetRole(participant.Role)
    end

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

        return
    end

    if stopMusic and roundPhase ~= "Intermission" then
        stopMusic()
    end

    joinRound:ToggleVisible((roundPhase == "Waiting") or (roundPhase == "Preparing"))

    if roundPhase == "Playing" then
        if ownRole and participant then
            -- local participants = LocalRoundInfo.GetAllParticipants()

            -- if ownRole.HighlightRoles then
            --     local highlightRoles = {}
            --     for _, v in ownRole.HighlightRoles do
            --         table.move(RoundHandler.GetRolesMatchingRelationship(LocalRoundInfo.GetAllRoles() or {}, ownRole, v), 1, #highlightRoles, #highlightRoles + 1, highlightRoles)
            --     end

            --     for _, role in highlightRoles do
            --         for _, p in RoundHandler.GetParticipantsWithRole(participants, role, participant) do
            --             local clone = Instance.new("Highlight")
            --             CollectionService:AddTag(clone, "AllyMarker")
            --             clone.FillTransparency = 1
            --             clone.OutlineColor = role.Colour
            --             clone.OutlineTransparency = 0
            --             clone.Parent = p.Player.Character
            --         end
            --     end
            -- end
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

        local highlights = UIManager.WaitForUI("Highlights").Object :: typeof(ReplicatedFirst.UIManager.UnregisteredUIs.Highlights)
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

    local toRegister = ReplicatedFirst.UIManager.UnregisteredUIs:FindFirstChild("Equipment Shop")
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