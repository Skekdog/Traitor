local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ViewCorpse = require(ReplicatedStorage.Shared.Actions.ViewCorpse)
local ThemesManager = require(ReplicatedStorage.Shared.Interface.UILib.ThemesManager)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local ui = UIManager.WaitForUI("Playerlist").Object :: typeof(UIManager.UnregisteredUIs.Playerlist)
local info = ui.Info
local list = ui.List

local layoutOrders = {
	["Alive"] = 0,
	["Missing"] = 1000,
	["Dead"] = 2000,
	["Spectating"] = 3000,
}

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

	local statusValue = LocalRoundInfo.PlayerStatuses()[plr.Name]
	local status = if statusValue then statusValue() else "Spectating"

	local marksVisible = (status == "Alive") and (plr ~= Players.LocalPlayer)
	for _, v in clone.Marks:GetChildren() do
		if v:IsA("TextButton") then
			v.Visible = marksVisible
		end
	end

	selectMark(clone.Marks, nil, plr)

	clone.Karma.Text = tostring(plr:GetAttribute("Karma"))
	clone.Score.Text = tostring(plr:GetAttribute("Score"))
	clone.Total.Text = tostring(plr:GetAttribute("TotalScore"))

	clone.SearchedIcon.Visible = not not LocalRoundInfo.PlayerCorpses()[plr.Name]

	movePlr(plr, status :: Types.ParticipantStatus)

	local roleValue = LocalRoundInfo.PlayerRoles()[plr.Name]
	local role = if roleValue then roleValue() else nil
	if not role then
		clone.Username:SetAttribute("KeepText")
		ThemesManager.UpdateThemeInstance(clone.Username)
	else
		clone.Username:SetAttribute("KeepText", true)
		clone.Username.TextColor3 = role.Definition.Color
	end
end

local function createPlr(plr: Player)
	local clone = ui.PlayerFrame:Clone()
	players[plr.Name] = clone

	clone.Username.Text = "@"..plr.Name
	clone.Username.TextColor3 = Color3.new()

	clone.Karma.Text = tostring(plr:GetAttribute("Karma"))
	clone.Score.Text = tostring(plr:GetAttribute("Score"))
	clone.Total.Text = tostring(plr:GetAttribute("TotalScore"))

	clone.SearchedIcon.Visible = not not LocalRoundInfo.PlayerCorpses()[plr.Name]

	pcall(function()
		clone.Avatar.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)

	clone.Visible = true
	clone.Name = "Player-" .. plr.Name
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
			ViewCorpse(plr)
		end
	end)

	plr:GetAttributeChangedSignal("Karma"):Connect(function()
		clone.Karma.Text = tostring(plr:GetAttribute("Karma"))
	end)

	updatePlr(plr, clone)

	return clone :: PlayerElement
end

local function recalculateCount(status: Types.ParticipantStatus)
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

	label.Text = `{status} ({count})`
end

local function getStatus(order: number): Types.ParticipantStatus
	order = (order // 1000) * 1000
	for _, v in list:GetChildren() do
		if not v:IsA("TextLabel") then
			continue
		end
		if v.LayoutOrder == order then
			local status = v.Name:split(" ")[1]
			assert(status == "Alive" or status == "Missing" or status == "Dead" or status == "Spectating", "Invalid status: " .. status)
			return status
		end
	end
	error("Failed to get status for order: "..order)
end

function movePlr(plr: Player, status: Types.ParticipantStatus)
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

LocalRoundInfo.PlayerRoles:Connect(function()
	for _, v in Players:GetPlayers() do
		updatePlr(v, findPlr(v.Name) or createPlr(v))
	end
end, true)

LocalRoundInfo.PlayerStatuses:Connect(function()
	for _, v in Players:GetPlayers() do
		updatePlr(v, findPlr(v.Name) or createPlr(v))
	end
end, true)

LocalRoundInfo.PlayerCorpses:Connect(function()
	for _, v in Players:GetPlayers() do
		updatePlr(v, findPlr(v.Name))
	end
end, true)

LocalRoundInfo.Gamemode:Connect(function(gamemode)
	if not gamemode then
		return
	end

	info.RoundInfo.Info.Gamemode.Text = "Gamemode: " .. GetDisplayName(gamemode)
	info.RoundInfo.Creators.Gamemode.Text = gamemode.Authors
end, true)

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)