local ui = script.Parent
local uiManager = require(game:GetService("ReplicatedFirst").UIManager)
local API = require(game.ReplicatedFirst.API)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hFrame, eFrame, sFrame = ui.Page.Highlights, ui.Page.Events, ui.Page.Scores
local eTemplate = eFrame.Template

ReplicatedStorage.OnClientEvent:Connect(function(phase,round,result)
	if (phase ~= "Highlights") or (round ~= "Main") then return end
	local soloVictor, music, victors = result.SoloVictor, result.Music[2], result.Victors
	local events, _scores, _highlights = result.Events, result.Scores, result.Highlights
	
	hFrame.Winners.TextColor3 = ReplicatedStorage.ClientServer.GetRoundInfo:InvokeServer("Main","Round").RoundInfo.Gamemode.Roles[victors].Colour
	hFrame.Winners.Text = (soloVictor and soloVictor:upper().." WINS") or "THE "..victors:upper().."S WIN"
	hFrame.Music:FindFirstChild("Text").Text = music
	
	for _,v in eFrame:GetChildren() do if (v.Name ~= "UIListLayout") and ((v.Name ~= "Template") and (v.Name ~= "EventFilters")) then v:Destroy() end end
	for _,v in sFrame:GetChildren() do if (v.Name ~= "UIListLayout") and (v.Name ~= "Template") then v:Destroy() end end
	
	--for _,v in highlights do
		
	--end
	for i,v in events do
		local e = eTemplate:Clone()
		
		e.TextLabel.Text = v.Text
		e.Time.Text = v.RoundTime
		
		local correctImage, correct = e.CorrectDamage, v.Correct
		if correct then
			correctImage.Image = "rbxassetid://6972510111"
			correctImage.Visible = true
		elseif correct == false then
			correctImage.Image = "rbxassetid://15000532008"
			correctImage.Visible = true
		else
			correctImage.Visible = false
		end
		
		e.SelfDefense.Visible = v.SelfDefense
		
		for _,k in eFrame.EventFilters:GetChildren() do
			if k:GetAttribute("Visible") then
				e.Visible = true
				break
			end
		end
		e.LayoutOrder = i+1
		
		e:SetAttribute("Category",v.Category)
		e.Name = "Event"..tostring(i)
		e.Parent = eFrame
	end
	
	uiManager.WaitForUI("Highlights","UserTriggered"):ToggleVisible(true)
end)

local pageOrders = {
	Events = 1,
	Highlights = 2,
	Scores = 3
}

local function showTab(tab)
	local curPage = script:GetAttribute("CurrentTab")
	if curPage == tab then
		return
	end
	script:SetAttribute("CurrentTab", tab)
	API.TransitionUIPage(ui.Page:FindFirstChild(curPage), pageOrders[curPage], ui.Page:FindFirstChild(tab), pageOrders[tab], UDim2.fromScale(0.5, 0.5))
end

local function _adjustEventFilter(filter,visible)
	for _,v in eFrame:GetChildren() do if v:GetAttribute("Category") == filter then v.Visible = visible end end
end

ui.EventsButton.MouseButton1Click:Connect(function() showTab("Events") end)
ui.HighlightsButton.MouseButton1Click:Connect(function() showTab("Highlights") end)
ui.ScoresButton.MouseButton1Click:Connect(function() showTab("Scores") end)

for _,v in eFrame.EventFilters:GetChildren() do
	if v.ClassName == "UIGridLayout" then continue end
	v.ImageLabel.MouseButton1Click:Connect(function()
		local visible = not v:GetAttribute("Visible")
		for _,k in eFrame:GetChildren() do if k:GetAttribute("Category") == v.Name then k.Visible = visible end end
		v.ImageLabel.Image = (visible and "rbxassetid://9155626912") or "rbxassetid://9155599240"
		v:SetAttribute("Visible",visible)
	end)
end

script:SetAttribute("CurrentTab", "Highlights")