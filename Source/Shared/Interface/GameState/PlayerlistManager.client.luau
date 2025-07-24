local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ViewCorpse = require(ReplicatedStorage.Shared.Actions.ViewCorpse)
local ThemesManager = require(ReplicatedStorage.Shared.Interface.UILib.ThemesManager)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local InstanceSignal = require(ReplicatedStorage.Shared.Util.InstanceSignal)

local ui = UIManager.WaitForUI("Playerlist").Object :: typeof(UIManager.UnregisteredUIs.Playerlist)
local info = ui.Info
local list = ui.List

local layoutOrders = {
	["Alive"] = 0,
	["Missing"] = 1000,
	["Dead"] = 2000,
	["Spectating"] = 3000,
}

type PlayerStatus = Types.ParticipantStatus | "Spectating"

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

local function toggleMarksVisible(clone: PlayerElement, visible: boolean): ()
	for _, v in clone.Marks:GetChildren() :: {any} do
		if not v:IsA("TextButton") then
			continue
		end
		v.Visible = visible
	end
end

local function createPlr(plr: Player)
	local participant = LocalParticipantInfo.GetParticipant(plr.Name)
	local clone = ui.PlayerFrame:Clone()
	players[plr.Name] = clone

	clone.Username.Text = "@" .. plr.Name

	pcall(function()
		clone.Avatar.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
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

	InstanceSignal.ListenAttribute(plr, "Karma", nil :: number?):Connect(function(karma)
		if not clone.Parent then
			return
		end
		clone.Karma.Text = tostring(plr:GetAttribute("Karma"))
	end, true)

	InstanceSignal.ListenAttribute(plr, "Score", nil :: number?):Connect(function(score)
		if not clone.Parent then
			return
		end
		clone.Score.Text = tostring(plr:GetAttribute("Score"))
	end, true)

	InstanceSignal.ListenAttribute(plr, "TotalScore", nil :: number?):Connect(function()
		if not clone.Parent then
			return
		end
		clone.Total.Text = tostring(plr:GetAttribute("TotalScore"))
	end, true)

	participant.Corpse:Connect(function(corpse)
		if not clone.Parent then
			return
		end
		clone.SearchedIcon.Visible = not not corpse
	end, true)

	participant.Role:Connect(function(role)
		if not clone.Parent then
			return
		end
		if role == Defaults.Role then
			clone.Username:SetAttribute("KeepText")
			ThemesManager.UpdateThemeInstance(clone.Username)
		else
			clone.Username:SetAttribute("KeepText", true)
			clone.Username.TextColor3 = role.Definition.Color
		end
	end, true)

	participant.Status:Connect(function(status)
		if not clone.Parent then
			return
		end
		movePlr(plr, status :: PlayerStatus)
		toggleMarksVisible(clone, status == "Alive" and plr ~= Players.LocalPlayer)
	end, true)

	return clone :: PlayerElement
end

local function recalculateCount(status: PlayerStatus)
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

local function getStatus(order: number): PlayerStatus
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

function movePlr(plr: Player, status: PlayerStatus)
	local clone = findPlr(plr.Name) or createPlr(plr)
	local oldOrder = clone.LayoutOrder
	clone.LayoutOrder = layoutOrders[status] + 1

	recalculateCount(getStatus(oldOrder))

	if status == "Alive" or status == "Spectating" then
		clone.SearchedIcon.Visible = false
	end

	recalculateCount(status)
end

if false then
	(movePlr :: any)()
end

local function removePlr(plr: Player)
	local f = findPlr(plr.Name)
	players[plr.Name] = nil
	if f then
		f:Destroy()
		recalculateCount(getStatus(f.LayoutOrder))
	end
end

Players.PlayerRemoving:Connect(removePlr)

LocalRoundInfo.Gamemode:Connect(function(gamemode)
	if not gamemode then
		return
	end

	info.RoundInfo.Info.Gamemode.Text = "Gamemode: " .. GetDisplayName(gamemode)
	info.RoundInfo.Creators.Gamemode.Text = gamemode.Authors
end, true)

Players.PlayerAdded:Connect(function(plr)
	if not findPlr(plr.Name) then
		createPlr(plr)
	end
end)

for _, v in Players:GetPlayers() do
	if not findPlr(v.Name) then
		createPlr(v)
	end
end

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)