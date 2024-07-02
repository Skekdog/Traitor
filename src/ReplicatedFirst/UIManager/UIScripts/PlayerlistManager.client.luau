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

type PlayerElement = typeof(ui.PlayerFrame)
local function findPlr(plrName: string)
	return list:FindFirstChild("Player-"..plrName) :: PlayerElement
end

function updatePlr(plr: Player, clone: any)
	local participant: Types.ClientOwnParticipant | Types.ClientParticipant?
	if plr == Players.LocalPlayer then
		participant = LocalRoundInfo.GetOwnParticipant()
	else
		participant = LocalRoundInfo.GetParticipantInfo(plr.Name)
	end

	movePlr(plr, if participant then participant.Status else "Spectating")

	if not participant then
		ThemesManager.UpdateThemeInstance(clone.Username)
		return
	end

	local role = LocalRoundInfo.GetRole(participant.Role)
	if role.Name == "" or LocalRoundInfo.GetRoundPhase() == "Destroy" then
		clone.Username:SetAttribute("StyleData")
		ThemesManager.UpdateThemeInstance(clone.Username)
	else
		clone.Username:SetAttribute("StyleData", "KeepText")
		clone.Username.TextColor3 = role.Colour
	end
end

local function createPlr(plr: Player)
	local clone = ui.PlayerFrame:Clone()

	clone.Username.Text = "@"..plr.Name
	clone.Username.TextColor3 = Color3.new()

	clone.Karma.Text = tostring(ReplicatedStorage.ClientServer.GetKarma:InvokeServer(plr))
	clone.Total.Text = tostring(nil)
	clone.Score.Text = tostring(nil)

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
			if v.UIStroke.Enabled then
				plr:SetAttribute("Mark", "")
				v.UIStroke.Enabled = false
				return
			end

			for _, b in clone.Marks:GetChildren() :: {any} do
				if b.ClassName ~= "TextButton" then
					continue
				end
				b.UIStroke.Enabled = false
			end
			v.UIStroke.Enabled = true
			plr:SetAttribute("Mark", v.Name)
		end)
	end

	clone.MouseButton1Click:Connect(function()
		local order = (clone.LayoutOrder // 1000) * 1000
		if order == layoutOrders["Dead"] or order == layoutOrders["Missing"] then
			CorpseInfo(ReplicatedStorage.RoundHandler.SearchCorpse:InvokeServer(plr.Name))
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

function movePlr(plr: Player, status: Status)
	local clone = findPlr(plr.Name) or createPlr(plr)
	local oldOrder = (clone.LayoutOrder // 1000) * 1000
	clone.LayoutOrder = layoutOrders[status] + 1
	clone.Marks.Visible = status == "Alive"

	for _, v in list:GetChildren() do
		if not v:IsA("TextLabel") then
			continue
		end

		if v.LayoutOrder == oldOrder then
			local oldStatus = v.Text:split(" ")[1]
			if oldStatus == "Confirmed" then
				oldStatus = "Dead"
			end
			recalculateCount(oldStatus :: Status)
			break
		end
	end

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
	end
end

Players.PlayerRemoving:Connect(removePlr)
Players.PlayerAdded:Connect(function(plr)
	movePlr(plr, "Spectating")
end)

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

LocalRoundInfo.Listen("UpdateParticipant", function(p)
	local participant = p :: Types.ClientParticipant | string
	if type(participant) == "string" then
		removePlr(participant)
		return
	end
	updatePlr(participant.Player, findPlr(participant.Player.Name))
end);

(ReplicatedStorage:WaitForChild("RoundHandler") :: typeof(ReplicatedStorage.RoundHandler)).CorpseSearched.OnClientEvent:Connect(function(name: string)
	findPlr(name).SearchedIcon.Visible = true
end)

-- There is probably a better way to do this
LocalRoundInfo.Listen("MapName", function(mapName)
	info.RoundInfo.Info.Map.Text = "Map: "..mapName :: string
end)
LocalRoundInfo.Listen("MapAuthors", function(mapCreator)
	info.RoundInfo.Creators.Map.Text = mapCreator :: string
end)
LocalRoundInfo.Listen("GamemodeName", function(gamemodeName)
	info.RoundInfo.Info.Gamemode.Text = "Gamemode: "..gamemodeName :: string
end)
LocalRoundInfo.Listen("GamemodeAuthors", function(gamemodeCreator)
	info.RoundInfo.Creators.Gamemode.Text = gamemodeCreator :: string
end)

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)