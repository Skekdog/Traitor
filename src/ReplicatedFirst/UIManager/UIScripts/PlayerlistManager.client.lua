local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundHandlerTypes = require(ReplicatedFirst.RoundHandlerTypes)
local UIManager = require(script.Parent.Parent)

local ui = UIManager.WaitForUI("Playerlist").UI
local info = ui.Info
local list = ui.List

local layoutOrders = {
	["Alive"] = 0,
	["Missing"] = 1000,
	["Dead"] = 2000,
	["Spectating"] = 3000,
}

local function findPlr(plr: Player)
	return list:FindFirstChild("Player-"..plr.Name)
end

local function updatePlr(plr: Player, clone)
	local participant: RoundHandlerTypes.PartialParticipant? = ReplicatedStorage.RoundHandler.GetPartialParticipant:InvokeServer(plr.Name)
	if participant and participant.Role then
		clone.Username.TextColor3 = participant.Role.Colour
		clone.Username:SetAttribute("StyleData", "KeepText")
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
		clone.Avatar.Image, _ = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)

	clone.Visible = true
	clone.Name = "Player-"..plr.Name
	clone.Parent = list

	for _, v in clone.Marks:GetChildren() do
		v.MouseButton1Click:Connect(function()
			if v.UIStroke.Enabled then
				plr:SetAttribute("Mark", "")
				v.UIStroke.Enabled = false
				return
			end

			for _, b in clone.Marks:GetChildren() do
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
	clone.ViewBodyButton.MouseButton1Click:Connect(function()
		ReplicatedStorage.ClientServer.GetCorpseInfo:FireServer(plr.Name)
	end)

	updatePlr(plr, clone)

	return clone
end

local function movePlr(plr: Player, status: "Alive" | "Missing" | "Dead" | "Spectating")
	local clone = findPlr(plr) or createPlr(plr)
	
	clone.LayoutOrder = layoutOrders[status]+1

	clone.Marks.Visible = status ~= "Alive"
	clone.ViewBodyButton.Visible = (status ~= "Alive") and (status ~= "Spectating")
end

local function removePlr(plr: Player)
	local f = findPlr(plr)
	if f then
		f:Destroy()
	end
end

Players.PlayerRemoving:Connect(removePlr)
Players.PlayerAdded:Connect(function(plr)
	movePlr(plr, "Spectating")
end)

local participants: {RoundHandlerTypes.PartialParticipant} = ReplicatedStorage.RoundHandler.GetPartialParticipants
local plrToParticipant: {[Player]: RoundHandlerTypes.PartialParticipant} = {}

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

ReplicatedStorage.RoundHandler.RoundPhaseChanged:Connect(function()
	for _, plr in Players:GetPlayers() do
		updatePlr(plr, findPlr(plr))
	end
end)

ReplicatedStorage.RoundHandler.CorpseSearched:Connect(function(name)
	local plr = Players:FindFirstChild(name)
	if not plr then return end

	plr:SetAttribute("Searched", true)
end)

ReplicatedStorage.RoundHandler.MapChanged.OnClientEvent:Connect(function(mapCreator, map: string, gamemode: string, gamemodeCreator)
	info.RoundInfo.Info.Map.Text = "Map: "..map
	info.RoundInfo.Info.Gamemode.Text = "Gamemode: "..gamemode
	info.RoundInfo.Creators.Map.Text = mapCreator
	info.RoundInfo.Creators.Gamemode.Text = gamemodeCreator
end)

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)