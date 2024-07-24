local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CorpseInfo = require(script.Parent.CorpseInfo)
local Types = require(ReplicatedFirst.RoundHandler.Types)
local UIManager = require(script.Parent.Parent)
local ThemesManager = require(script.Parent.Parent.Parent.ThemesManager)
local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)

local ui = UIManager.WaitForUI("Playerlist").Object :: typeof(UIManager.UnregisteredUIs.Playerlist)
local info = ui.Info
local list = ui.List

local layoutOrders = {
	["Alive"] = 0,
	["Missing"] = 1000,
	["Dead"] = 2000,
	["Spectating"] = 3000,
}

local roundHandlerEvents = ReplicatedStorage:WaitForChild("RoundHandler")
local clientServer = ReplicatedStorage:WaitForChild("ClientServer")

type PlayerElement = typeof(ui.PlayerFrame)
local function findPlr(plrName: string)
	return list:FindFirstChild("Player-"..plrName) :: PlayerElement
end

local function selectMark(marks: Frame & any, button: (TextButton & any)?, plr: Player)
	if button and button.UIStroke.Enabled then
		plr:SetAttribute("Mark", "")
		plr:SetAttribute("MarkColour", Color3.new())
		button.UIStroke.Enabled = false
		return
	end

	for _, b in marks:GetChildren() :: {any} do
		if b.ClassName ~= "TextButton" then
			continue
		end
		b.UIStroke.Enabled = false
	end

	if not button then
		return
	end
	button.UIStroke.Enabled = true
	plr:SetAttribute("Mark", button.Name)
	plr:SetAttribute("MarkColour", button.TextColor3)
end

function updatePlr(plr: Player, clone: any)
	if not clone then
		return
	end
	local participant: Types.ClientOwnParticipant | Types.ClientParticipant?
	if plr == Players.LocalPlayer then
		participant = LocalRoundInfo.GetOwnParticipant()
	else
		participant = LocalRoundInfo.GetParticipantInfo(plr.Name)
	end

	local status = if participant then participant.Status else "Spectating"

	local marksVisible = (status == "Alive") and (plr ~= Players.LocalPlayer)
	for _, v in clone.Marks:GetChildren() do
		if v:IsA("TextButton") then
			v.Visible = marksVisible
		end
	end

	selectMark(clone.Marks, nil, plr)

	clone.Karma.Text = tostring(clientServer.GetKarma:InvokeServer(plr))
	clone.Score.Text = tostring(plr:GetAttribute("Score"))
	clone.Total.Text = tostring(plr:GetAttribute("TotalScore"))

	movePlr(plr, status :: any)

	if not participant then
		return ThemesManager.UpdateThemeInstance(clone.Username)
	end

	local role = LocalRoundInfo.GetRole(participant.Role)
	if role.Name == "" or LocalRoundInfo.GetRoundPhase() == "Destroy" then
		ThemesManager.UpdateThemeInstance(clone.Username)
	else
		clone.Username:SetAttribute("KeepText", true)
		clone.Username.TextColor3 = role.Colour
	end
end

local function createPlr(plr: Player)
	local clone = ui.PlayerFrame:Clone()

	clone.Username.Text = "@"..plr.Name
	clone.Username.TextColor3 = Color3.new()

	clone.Karma.Text = tostring(clientServer.GetKarma:InvokeServer(plr))
	clone.Score.Text = tostring(plr:GetAttribute("Score"))
	clone.Total.Text = tostring(plr:GetAttribute("TotalScore"))

	pcall(function()
		clone.Avatar.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)

	clone.Visible = true
	clone.Name = "Player-"..plr.Name
	clone.Parent = list :: any

	for _, v in clone.Marks:GetChildren() :: {any} do
		if not v:IsA("TextButton") then
			continue
		end
		v.MouseButton1Click:Connect(function()
			selectMark(clone.Marks, v, plr)
		end)
	end

	clone.MouseButton1Click:Connect(function()
		local order = (clone.LayoutOrder // 1000) * 1000
		if order == layoutOrders["Dead"] or order == layoutOrders["Missing"] then
			CorpseInfo(roundHandlerEvents.SearchCorpse:InvokeServer(plr.Name))
		end
	end)

	updatePlr(plr, clone)

	return clone :: PlayerElement
end

type Status = "Alive" | "Missing" | "Dead" | "Spectating"
local function recalculateCount(status: Status)
	local count = -1 -- Because this also counts the header
	for _, v in list:GetChildren() do
		if not v:IsA("GuiObject") then
			continue
		end

		if v.LayoutOrder // 1000 == (layoutOrders[status] / 1000) then
			count += 1
		end
	end

	local label = list:FindFirstChild(status) :: TextLabel
	label.Visible = count > 0

	if status == "Dead" then
		status = "Confirmed Dead" :: any
	end
	label.Text = `{status} ({count})`
end

local function getStatus(order: number): Status
	order = (order // 1000) * 1000
	for _, v in list:GetChildren() do
		if not v:IsA("TextLabel") then
			continue
		end
		if v.LayoutOrder == order then
			local status = v.Text:split(" ")[1]
			if status == "Confirmed" then
				status = "Dead"
			end
			return status :: Types.ParticipantStatus
		end
	end
	error("Failed to get status for order: "..order)
end

function movePlr(plr: Player, status: Status)
	local clone = findPlr(plr.Name) or createPlr(plr)
	local oldOrder = clone.LayoutOrder
	clone.LayoutOrder = layoutOrders[status] + 1

	recalculateCount(getStatus(oldOrder))

	if status == "Alive" or status == "Spectating" then
		clone.SearchedIcon.Visible = false
	end

	recalculateCount(status)
end

local function removePlr(plr: Player | string)
	local plrName: string
	if typeof(plr) == "string" then
		plrName = plr
	else
		plrName = plr.Name
	end

	local f = findPlr(plrName)
	if f then
		f:Destroy()
		recalculateCount(getStatus(f.LayoutOrder))
	end
end

Players.PlayerAdded:Connect(function(plr)
	movePlr(plr, "Spectating")
end)

Players.PlayerRemoving:Connect(removePlr)

local participants = LocalRoundInfo.GetAllParticipants()
local plrToParticipant: {[Player]: Types.ClientParticipant} = {}

for _, v in participants do
	plrToParticipant[v.Player] = v
end

for _, plr in Players:GetPlayers() do
	if plrToParticipant[plr] then
		movePlr(plr, plrToParticipant[plr].Status)
	else
		movePlr(plr, "Spectating")
	end
end

LocalRoundInfo.Listen("UpdateOwnParticipant", function(p)
	updatePlr(Players.LocalPlayer, findPlr(Players.LocalPlayer.Name))
end)

LocalRoundInfo.Listen("UpdateParticipant", function(participant: Types.ClientParticipant | string)
	if type(participant) == "string" then
		local player = Players:FindFirstChild(participant) :: Player
		if not player then
			return removePlr(participant)
		end
		return updatePlr(player, findPlr(participant))
	end
	updatePlr(participant.Player, findPlr(participant.Player.Name))
end)

roundHandlerEvents.CorpseSearched.OnClientEvent:Connect(function(name: string)
	findPlr(name).SearchedIcon.Visible = true
end)

-- There is probably a better way to do this
LocalRoundInfo.Listen("MapName", function(mapName)
	info.RoundInfo.Info.Map.Text = "Map: "..mapName
end)
LocalRoundInfo.Listen("MapAuthors", function(mapCreator)
	info.RoundInfo.Creators.Map.Text = mapCreator
end)
LocalRoundInfo.Listen("GamemodeName", function(gamemodeName)
	info.RoundInfo.Info.Gamemode.Text = "Gamemode: "..gamemodeName
end)
LocalRoundInfo.Listen("GamemodeAuthors", function(gamemodeCreator)
	info.RoundInfo.Creators.Gamemode.Text = gamemodeCreator
end)

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)