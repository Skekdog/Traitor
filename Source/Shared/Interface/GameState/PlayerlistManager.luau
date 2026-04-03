local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ViewCorpse = require(ReplicatedStorage.Shared.Actions.ViewCorpse)
local HookClientMessage = require(ReplicatedStorage.Shared.Interface.Chat.HookClientMessage)
local ThemesManager = require(ReplicatedStorage.Shared.Interface.UILib.ThemesManager)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)
local Types = require(ReplicatedStorage.API.Types)
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
	button.UIStroke.Color = Color3.new(1, 1, 1)
	button.UIStroke.Transparency = 0.4
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

HookClientMessage.Hook(function(message)
	if not message.TextSource and not message.Metadata:find("Player_") then
		return
	end

	local plr: Player?
	if message.TextSource then
		plr = Players:GetPlayerByUserId(message.TextSource.UserId)
	else
		local tags = message.Metadata:split(" ")
		for _, tag in tags do
			if tag:find("Player_") then
				local id = tonumber(tag:split("Player_")[2]) or 0
				plr = Players:GetPlayerByUserId(id)
			end
		end
	end

	if plr and plr:GetAttribute("Muted") then
		message.Metadata ..= " MUTED"
	end
end)

local function createPlr(plr: Player)
	local participant = LocalParticipantInfo.GetParticipant(plr.Name)
	local clone = ui.PlayerFrame:Clone()
	players[plr.Name] = clone

	clone.Username.Text = "@" .. plr.Name

	task.spawn(pcall, function()
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

	if plr ~= Players.LocalPlayer then
		clone.Mute.Text = if plr:GetAttribute("Muted") then "<s>Aa</s>" else "Aa"
		clone.Mute.Activated:Connect(function()
			local isMuted = not plr:GetAttribute("Muted")
			plr:SetAttribute("Muted", isMuted)

			clone.Mute.Text = if isMuted then "<s>Aa</s>" else "Aa"
		end)
	else
		clone.Mute.Text = ""
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
		karma = karma or 1000
		assert(karma)
		clone.Karma.Text = tostring(math.round(karma))
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

	if plr == Players.LocalPlayer then
		TweenService:Create(clone, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, -1, true), {BackgroundColor3 = Color3.new(1, 1, 1)}):Play()
	end

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

	local oldStatus = getStatus(oldOrder)
	if oldStatus ~= "Alive" and status ~= "Alive" then
		selectMark(clone.Marks, nil, plr)
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

	info.RoundInfo.Gamemode.GamemodeName.Text = "Gamemode: " .. GetDisplayName(gamemode)
	info.RoundInfo.Gamemode.GamemodeAuthors.Text = gamemode.Authors
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

return nil