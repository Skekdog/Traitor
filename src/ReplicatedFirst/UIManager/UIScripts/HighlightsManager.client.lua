local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local API = require(ReplicatedFirst.API)
local Types = require(ReplicatedFirst.RoundHandler.Types)
local uiManager = require(ReplicatedFirst.UIManager)

local UI: uiManager.UI & {UI: typeof(ReplicatedFirst.UIManager.UnregisteredUIs.UserTriggered.Highlights)} = uiManager.WaitForUI("Highlights")
local page = UI.UI.Page

local hFrame, eFrame, sFrame = page.Highlights, page.Events, page.Scores
local eTemplate = eFrame.Template

ReplicatedStorage.RoundHandler.SendHighlights.OnClientEvent:Connect(function(highlights: {Types.RoundHighlight}, events: {Types.UserFacingRoundEvent}, scores: {[Types.Participant]: Types.ParticipantScoring}, victors: Types.Role)
	print(highlights)
	hFrame.Winners.Text = `THE {victors.Name:upper()} WIN`
	hFrame.Winners.TextColor3 = victors.Colour

	for _, v in eFrame:GetChildren() do
		if v.ClassName ~= "UIListLayout" and v.Name ~= "Template" and v.Name ~= "EventFilters" then
			v:Destroy()
		end
	end
	for _, v in sFrame:GetChildren() do
		if v.ClassName ~= "UIListLayout" and v.Name ~= "Template" then
			v:Destroy()
		end
	end
	for _, v in hFrame.Highlights:GetChildren() :: any do
		if v.ClassName == "Frame" then
			v.Description.Text = ""
			v.Highlight.Text = ""
		end
	end

	for i, v in highlights do
		if i >= 5 then
			break
		end
		local h = hFrame.Highlights:FindFirstChild("Highlight"..tostring(i)) :: any
		h.Description.Text = v.Description
		h.Highlight.Text = v.Name
	end
	-- todo: need something for syncing music

	for _, v in events do
		local e = eTemplate:Clone()
		e.TextLabel.Text = v.Text
		e.Time.Text = API.ToRoundTime(ReplicatedFirst.ClientStorage:GetAttribute("RoundStartTime"), v.Timestamp)
		e.Visible = true
		e.Name = "ActiveEvent"
		e.Parent = eFrame
	end
	
	UI:ToggleVisible(true)
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
	API.TransitionUIPage(page:FindFirstChild(curPage) :: any, pageOrders[curPage], page:FindFirstChild(tab) :: any, pageOrders[tab], UDim2.fromScale(0.5, 0.5))
end

local function _adjustEventFilter(filter, visible)
	for _, v in eFrame:GetChildren() :: any do
		if v:GetAttribute("Category") == filter then
			v.Visible = visible
		end
	end
end

page.Parent.EventsButton.MouseButton1Click:Connect(function() showTab("Events") end)
page.Parent.HighlightsButton.MouseButton1Click:Connect(function() showTab("Highlights") end)
page.Parent.ScoresButton.MouseButton1Click:Connect(function() showTab("Scores") end)

for _, v in eFrame.EventFilters:GetChildren() :: any do
	if v.ClassName == "UIGridLayout" then
		continue
	end
	v.ImageLabel.MouseButton1Click:Connect(function()
		local visible = not v:GetAttribute("Visible")
		for _, k in eFrame:GetChildren() :: any do
			if k:GetAttribute("Category") == v.Name then
				k.Visible = visible
			end
		end
		v.ImageLabel.Image = (visible and "rbxassetid://9155626912") or "rbxassetid://9155599240"
		v:SetAttribute("Visible", visible)
	end)
end

script:SetAttribute("CurrentTab", "Highlights")