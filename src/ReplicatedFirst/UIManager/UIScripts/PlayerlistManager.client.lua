local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

local API = require(game.ReplicatedFirst.API)
local uiManager = require(game:GetService("ReplicatedFirst").UIManager)

local ui = uiManager.WaitForUI("Playerlist").UI
local info = ui.Info
local list = ui.List

--This allows up to 999 players in each category which should be plenty
--In any case you can always just go up a magnitude
--This does mean you can't have more than 9 stati (10 at a stretch) - but that doesn't matter does it
--Also, stati is a fun word
local orderMap = {
	["Alive"] = 1000,
	["Missing"] = 2000,
	["Confirmed Dead"] = 3000,
	["Spectating"] = 4000,
}
local layoutMap = {
	["1"] = "Alive",
	["2"] = "Missing",
	["3"] = "Confirmed Dead",
	["4"] = "Spectating",
}

local function createPlrs(plrs, status)
	local roundInfo = RS.ClientServer.GetRoundInfo:InvokeServer("Main", "Round+PlayerRoles")
	
	local c
	if status == "Alive" then c = ui["Alive-Player"] elseif status == "Spectating" then c = ui["Spectating-Player"] else c = ui["Confirmed Dead-Player"] end
	local initOffset = orderMap[status]
	local orderOffset = initOffset
	for _, v in list:GetChildren() do
		if (#v.Name:split("-") > 1) and (tostring(v.LayoutOrder):sub(1, 1) == initOffset/1000) then orderOffset += 1 end
	end
	local elms = {}
	for i, v in plrs do
		if API.FindFirstChildSplit(list, "-", v.Name, 2) then continue end
		local elm = c:Clone()
		elm.Name = status.."-"..v.Name
		elm.Parent = list
		if v.Name == Players.LocalPlayer.Name and status == "Alive" then
			elm.Username.Size += UDim2.new(0.1, 20, 0, 0)
		end
		elm.Username.Text = "@"..v.Name
		if gm then
			local role = roundInfo.PlayerRoles[v.Name]
			if role ~= "__!!Unknown" and role and gm then
				elm.Username.TextColor3 = gm.Roles[role].Colour
				elm.Username:SetAttribute("StyleData", "KeepText")
			else
				elm.Username.TextColor3 = elm:GetAttribute("DefaultTextColour")
			end
		end
		pcall(function()elm.Avatar.Image = table.pack(Players:GetUserThumbnailAsync(v.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48))[1]end)
		elm.Karma.Text = tostring(ReplicatedStorage.ClientServer.GetKarma:InvokeServer(v))
		elm.Points.Text = tostring(v:GetAttribute("Points"))
		elm.Total.Text = tostring(v:GetAttribute("Total"))
		elm.LayoutOrder = orderOffset+i
		elm.Visible = true
		
		if v:GetAttribute("Searched") and elm.ClassName == "TextButton" then elm.Search.Visible = true end
		
		table.insert(elms, elm)
		
		local marks = {}
		for _, b in elm:GetChildren() do
			if b.ClassName == "TextButton" then
				if v.Name == Players.LocalPlayer.Name then
					b:Destroy()
					continue
				end
				table.insert(marks, b)
				b.MouseButton1Click:Connect(function()
					if b.UIStroke.Enabled then for _, n in marks do n.UIStroke.Enabled = false end v:SetAttribute("Mark", "") return end
					for _, n in marks do n.UIStroke.Enabled = false end
					b.UIStroke.Enabled = true
					v:SetAttribute("Mark", b.Name:upper())
					v:SetAttribute("MarkColour", b.TextColor3)
				end)
			end
		end
		
		if elm.ClassName == "TextButton" then
			elm.MouseButton1Click:Connect(function()
				RS.ClientServer.GetCorpseInfo:InvokeServer(v.Name)
			end)
		end
		
		if v.Name == Players.LocalPlayer.Name then
			elm:SetAttribute("Style", "Primary")
			uiManager.UpdateThemeInstance(elm)
			TS:Create(elm, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, math.huge, true), {BackgroundTransparency=0}):Play()
		end
	end
	list:FindFirstChild(status).Text =  status.." ("..tostring(orderOffset+#plrs-initOffset)..")"
	return elms
end

local function countCats()
	local counts = {["Alive"]=0, ["Confirmed Dead"]=0, ["Missing"]=0, ["Spectating"]=0}
	for _, v in list:GetChildren() do
		if (v.ClassName == "UIListLayout") or (counts[v.Name]) then continue end
		counts[layoutMap[tostring(v.LayoutOrder):sub(1, 1)]] += 1
	end
	for _, v in list:GetChildren() do
		if counts[v.Name] then v.Text =  v.Name.." ("..tostring(counts[v.Name])..")" end
	end
end

local function adjustElements(elms)
	local decreasePerStatus = {["1"]=0, ["2"]=0, ["3"]=0, ["4"]=0}
	for _, v in elms do
		decreasePerStatus[tostring(v.LayoutOrder):sub(1, 1)] += 1
	end
	
	local indexes = {["1"]=0, ["2"]=0, ["3"]=0, ["4"]=0}
	for _, v in list:GetChildren() do
		if (#v.Name:split("-") > 1) and (not table.find(elms, v)) then
			local orderOffset = orderMap[v.Name:split("-")[1]]
			indexes[tostring(orderOffset/1000)] += 1
			v.LayoutOrder = orderOffset+indexes[tostring(orderOffset/1000)]
		end
	end
end

local function removePlrs(plrs)
	local elms = {}
	for _, v in plrs do
		local elm = API.FindFirstChildSplit(list, "-", v.Name, 2)
		table.insert(elms, elm)
	end
	
	adjustElements(elms)
	for _, v in elms do v:Destroy() end
	countCats()
end

local function changeStati(_, plrs, status)
	removePlrs(plrs)
	adjustElements(createPlrs(plrs, status))
	countCats()
end

RS.ServerClient.PlayerStateChange.OnClientEvent:Connect(changeStati)
RS.ServerClient.CorpseSearched.OnClientEvent:Connect(function(name)
	local elm = API.FindFirstChildSplit(list, "-", name, 2)
	if elm.ClassName == "TextButton" then
		Players[name]:SetAttribute("Searched", true)
		elm.Search.Visible = true
	end
end)

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

Players.PlayerRemoving:Connect(function(plr)removePlrs({plr})end)

RS.ServerClient.MapChanged.OnClientEvent:Connect(function(mapCreator, map: string, gamemode: string, gamemodeCreator)
	info.RoundInfo.Info.Map.Text = "Map: "..map
	info.RoundInfo.Info.Gamemode.Text = "Gamemode: "..gamemode
	info.RoundInfo.Creators.Map.Text = mapCreator
	info.RoundInfo.Creators.Gamemode.Text = gamemodeCreator
end)