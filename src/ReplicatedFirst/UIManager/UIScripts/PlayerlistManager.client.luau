local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedFirst.RoundHandler.Types)
local UIManager = require(script.Parent.Parent)
local LocalRoundInfo = require(script.Parent.Parent.Parent.LocalRoundInfo)

local ui = UIManager.WaitForUI("Playerlist").Object :: typeof(ReplicatedFirst.UIManager.UnregisteredUIs.Playerlist)
local info = ui.Info
local list = ui.List

local layoutOrders = {
	["Alive"] = 0,
	["Missing"] = 1000,
	["Dead"] = 2000,
	["Spectating"] = 3000,
}

local function findPlr(plrName: string)
	return list:FindFirstChild("Player-"..plrName) :: TextButton
end

function updatePlr(plr: Player, clone: any)
	local participant: Types.Participant? | Types.PartialParticipant?
	if plr == Players.LocalPlayer then
		participant = LocalRoundInfo.GetOwnParticipant()
	else
		participant = LocalRoundInfo.GetParticipantInfo(plr.Name)
	end
	if participant and participant.Role then
		clone.Username.TextColor3 = participant.Role.Colour
		clone.Username:SetAttribute("StyleData", "KeepText")
		movePlr(plr, participant.Status)
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

	plr:GetAttributeChangedSignal("Searched"):Once(function()
		clone.SearchedIcon.Visible = true
	end)
	clone.SearchedIcon.Visible = plr:GetAttribute("Searched")
	clone.MouseButton1Click:Connect(function()
		if (clone.LayoutOrder // 1000) == layoutOrders["Dead"] or (clone.LayoutOrder // 1000) == layoutOrders["Missing"] then
			ReplicatedStorage.ClientServer.GetCorpseInfo:FireServer(plr.Name)
		end
	end)

	updatePlr(plr, clone)

	return clone
end

function movePlr(plr: Player, status: "Alive" | "Missing" | "Dead" | "Spectating")
	local clone: any = findPlr(plr.Name) or createPlr(plr)
	clone.LayoutOrder = layoutOrders[status]+1
	clone.Marks.Visible = status == "Alive"
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
local plrToParticipant: {[Player]: Types.PartialParticipant} = {}

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

LocalRoundInfo.Listen("UpdateOwnParticipant", function(participant: Types.Participant?)
	if not participant then
		return
	end
	updatePlr(Players.LocalPlayer, findPlr(Players.LocalPlayer.Name))
end)

LocalRoundInfo.Listen("UpdateParticipant", function(participant: Types.PartialParticipant | string)
	if type(participant) == "string" then
		removePlr(participant)
		return
	end
	updatePlr(participant.Player, findPlr(participant.Player.Name))
end)

ReplicatedStorage.RoundHandler.CorpseSearched.OnClientEvent:Connect(function(name)
	local plr = Players:FindFirstChild(name)
	if not plr then
		return
	end

	plr:SetAttribute("Searched", true)
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