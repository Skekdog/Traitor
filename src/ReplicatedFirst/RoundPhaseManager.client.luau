local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedFirst.RoundHandler.Types)
local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local API = require(ReplicatedFirst.API)
local UIManager = require(ReplicatedFirst.UIManager)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)

local vote = UIManager.WaitForUI("VotingScreen") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.VotingScreen)}

local roundHandlerEvents = ReplicatedStorage:WaitForChild("RoundHandler")
for _, v in roundHandlerEvents.GetMaps:InvokeServer() do
	local clone = vote.Object.Sample:Clone()
	clone.Text = v
	clone.Visible = true
	clone.Name = v
	clone.Parent = vote.Object.Choices :: any

    clone.MouseButton1Click:Connect(function()
        roundHandlerEvents.VoteMap:FireServer(v)
    end)
end

local ownParticipant: Types.ClientOwnParticipant?
local ownRole: Types.Role?

LocalRoundInfo.Listen("UpdateOwnParticipant", function(participant: Types.ClientOwnParticipant?)
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

LocalRoundInfo.Listen("UpdateParticipant", function(participant: Types.ClientParticipant | string)
    if type(participant) == "string" then
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
end)

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

    if not ownParticipant or not Players.LocalPlayer.Character then
        LocalRoundInfo.SetSpectating(true)
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

roundHandlerEvents.VoteMap.OnClientEvent:Connect(function(allow)
    vote:ToggleVisible(allow)
end)

local timeTarget = 0
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

	roundInfo.TopBar.Timer.Text = API.ToRoundTime(time, timeTarget)
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
LocalRoundInfo.Listen("UpdateOwnParticipant", function(participant: Types.ClientOwnParticipant?)
    local role
    if participant then
        role = LocalRoundInfo.GetRole(participant.Role)
    end
    
    if not participant or role.Name == "" then
        if equipmentShop then
            equipmentShop:Unregister()
            equipmentShop = nil
        end
        roundInfo.TopBar.Role.TextColor3 = Color3.new(1, 1, 1)
        roundInfo.TopBar.Role.Text = if LocalRoundInfo.GetRoundPhase() == "Destroy" then "SPECTATING" else "PREPARING"
        return
    end

    roundInfo.TopBar.Role.Text = role.Name
    roundInfo.TopBar.Role.TextColor3 = role.Colour

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
        
        local entry = shopObject.EquipmentEntry:Clone()
        entry:SetAttribute("CreditCost", equipment.Cost)
        entry:SetAttribute("Description", equipment.Description)
        
        entry.Image = equipment.Icon
        entry.Name = equipment.Name
        entry.Visible = true
        entry.Parent = shopObject.ScrollingFrame :: any
    end
end)

LocalRoundInfo.Listen("RoundPhase", update)
update(LocalRoundInfo.GetRoundPhase())