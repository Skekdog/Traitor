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
local players: {[string]: PlayerElement?} = {}
local function findPlr(plrName: string)
	return players[plrName]
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

function updatePlr(plr: Player, clone: PlayerElement?)
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
		clone.Username:SetAttribute("KeepText")
		return ThemesManager.UpdateThemeInstance(clone.Username)
	end

	local role = LocalRoundInfo.GetRole(participant.Role)
	if role.Name == "" or LocalRoundInfo.GetRoundPhase() == "Destroy" then
		clone.Username:SetAttribute("KeepText")
		ThemesManager.UpdateThemeInstance(clone.Username)
	else
		clone.Username:SetAttribute("KeepText", true)
		clone.Username.TextColor3 = role.Colour
	end
end

local function createPlr(plr: Player)
	local clone = ui.PlayerFrame:Clone()
	players[plr.Name] = clone

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

local function removePlr(plr: Player)
	local f = findPlr(plr.Name)
	players[plr.Name] = nil
	if f then
		f:Destroy()
		recalculateCount(getStatus(f.LayoutOrder))
	end
end

if false then -- This looks stupid but that's because it is. This doesn't do anything at runtime instead it silences the error about undefined global
	(movePlr :: any)()
end

Players.PlayerRemoving:Connect(removePlr)

LocalRoundInfo.Listen("UpdateOwnParticipant", function(player)
	updatePlr(player, findPlr(player.Name) or createPlr(player))
end)

LocalRoundInfo.Listen("UpdateParticipant", function(player: Player, participant: Types.ClientParticipant?)
	if not player:IsDescendantOf(Players) then
		return removePlr(player)
	end
	if not participant then
		movePlr(player, "Spectating")
	end
	updatePlr(player, findPlr(player.Name) or createPlr(player))
end)

roundHandlerEvents.CorpseSearched.OnClientEvent:Connect(function(name: string)
	local element = findPlr(name)
	if element then
		element.SearchedIcon.Visible = true
	end
end)

-- There is probably a better way to do this
LocalRoundInfo.Listen("MapName", function(mapName)
	info.RoundInfo.Info.Map.Text = "Map: "..mapName
end, true)
LocalRoundInfo.Listen("MapAuthors", function(mapCreator)
	info.RoundInfo.Creators.Map.Text = mapCreator
end, true)
LocalRoundInfo.Listen("GamemodeName", function(gamemodeName)
	info.RoundInfo.Info.Gamemode.Text = "Gamemode: "..gamemodeName
end, true)
LocalRoundInfo.Listen("GamemodeAuthors", function(gamemodeCreator)
	info.RoundInfo.Creators.Gamemode.Text = gamemodeCreator
end, true)

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)