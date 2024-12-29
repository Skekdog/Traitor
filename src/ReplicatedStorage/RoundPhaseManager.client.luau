local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ThemesManager = require(script.Parent.ThemesManager)
local ToRoundTime = require(script.Parent.ToRoundTime)
local Types = require(script.Parent.RoundHandler.Types)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local UIManager = require(script.Parent.UIManager)
local MapVotingScreen = require(script.Parent.UIManager.UIScripts.MapVotingScreen)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)



local roundHandlerEvents = ReplicatedStorage:WaitForChild("RoundHandler")

local ownParticipant: Types.ClientOwnParticipant?
local ownRole: Types.Role?

local function highlight(participant: Types.ClientParticipant)
    local clone = Instance.new("Highlight")
    CollectionService:AddTag(clone, "AllyMarker")
    clone.FillTransparency = 1
    clone.OutlineColor = LocalRoundInfo.GetRole(participant.Role).Colour
    clone.OutlineTransparency = 0
    clone.Parent = participant.Player.Character
end

local function highlightParticipant(player: Player, participant: Types.ClientParticipant?)
    if not participant then
        return
    end

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
end

LocalRoundInfo.Listen("UpdateParticipant", highlightParticipant)

local function update(roundPhase)
    if roundPhase == "Destroy" then
        for _, v in CollectionService:GetTagged("AllyMarker") do
            v:Destroy()
        end

        for _, v in Players:GetPlayers() do
            v:SetAttribute("Mark", "")
        end

        LocalRoundInfo.SetSpectating(false)

        return
    end
    
    if roundPhase == "Highlights" then
        local endInfo = LocalRoundInfo.GetRoundEndInfo()
        assert(endInfo)

        local music = endInfo.Music
        if not music then
            return
        end
        local highlights = UIManager.WaitForUI("Highlights").Object :: typeof(UIManager.UnregisteredUIs.Highlights)
        highlights.Page.Highlights.Music.Text.Text = music.Name
    end
end

roundHandlerEvents.VoteMap.OnClientEvent:Connect(MapVotingScreen)

local timeTarget = LocalRoundInfo.GetTimeMilestone()
local paused = false
local lastTime = ""
local function updateTimer(time: number)
    if paused then
		if math.round(time) % 2 == 1 then
			roundInfo.TopBar.Timer.Text = "PAUSED"
		else
			roundInfo.TopBar.Timer.Text = lastTime
		end
		return
	end

	roundInfo.TopBar.Timer.Text = ToRoundTime(time, timeTarget)
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
    lastTime = roundInfo.TopBar.Timer.Text
    paused = isPaused
end)

local equipmentShop: UIManager.UI?
LocalRoundInfo.Listen("UpdateOwnParticipant", function(player: Player, participant: Types.ClientOwnParticipant?)
    local role
    if participant then
        role = LocalRoundInfo.GetRole(participant.Role)
    end

    ownParticipant = participant
    if ownParticipant then
        ownRole = role
        for _, v in LocalRoundInfo.GetAllParticipants() do
            highlightParticipant(player, v)
        end
    else
        ownRole = nil
    end

    -- Because this relies on UpdateOwnParticipant it will not update when another player creates a round. But at this point I really do not care this has caused me enough misery already, it gets fixed when the round starts anyway. Who would've thought a FUCKING SPECTATE MENU would be so difficult to create!?
    local phase = LocalRoundInfo.GetRoundPhase()
    local function trySpectate(): boolean
        if player.Character then
            return false
        end

        if phase == "Destroy" then
            return false
        end

        if not ownParticipant then
            return true
        end

        if not player.Character and phase ~= "Waiting" and phase ~= "Preparing" then
            return true
        end

        return false
    end
    LocalRoundInfo.SetSpectating(trySpectate())
    
    local roleLabel = roundInfo.TopBar.Role
    if not participant or role.Name == "" then
        if equipmentShop then
            equipmentShop:Unregister()
            equipmentShop = nil
        end

        roleLabel.Text = if LocalRoundInfo.GetRoundPhase() == "Destroy" then "SPECTATING" else "PREPARING"
        roleLabel:SetAttribute("KeepText")
        ThemesManager.UpdateThemeInstance(roleLabel)
        return
    end

    roleLabel.Text = role.Name
    roleLabel:SetAttribute("KeepText", true)
    roleLabel.TextColor3 = role.Colour

    if not role.EquipmentShop or #role.EquipmentShop <= 0 then
        if equipmentShop then
            equipmentShop:Unregister()
            equipmentShop = nil
        end
        return
    end

    local shopObject = UIManager.UnregisteredUIs:FindFirstChild("Equipment Shop")
    if not shopObject then
        return
    end

    equipmentShop = UIManager.RegisterUI(shopObject)
    shopObject.Reset:Fire()
    
    for _, v in shopObject.ScrollingFrame:GetChildren() do
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
        assert(equipment.Icon and equipment.Description and equipment.Cost, `Equipment {v} is missing an icon, description, or cost.`)
        
        local entry = shopObject.EquipmentEntry:Clone()
        entry:SetAttribute("CreditCost", equipment.Cost)
        entry:SetAttribute("Description", equipment.Description)

        if equipment.Extras and equipment.Extras.RespectTheme then
            entry:SetAttribute("UpdateImage", true)
            entry:AddTag("StyledUI")
        end
        
        entry.Image = equipment.Icon
        entry.Name = equipment.Name
        entry.Visible = true
        entry.Parent = shopObject.ScrollingFrame
    end
end)

LocalRoundInfo.Listen("RoundPhase", update)
update(LocalRoundInfo.GetRoundPhase())