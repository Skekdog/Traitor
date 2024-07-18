local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIAnimation = require(script.Parent.Parent.Parent.UIAnimation)
local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local API = require(ReplicatedFirst.API)
local Types = require(ReplicatedFirst.RoundHandler.Types)
local uiManager = require(ReplicatedFirst.UIManager)

local UI = uiManager.WaitForUI("Highlights") :: uiManager.UI & {Object: typeof(uiManager.UnregisteredUIs.Highlights)}
local page = UI.Object.Page

local hFrame, eFrame, sFrame = page.Highlights, page.Events, page.Scores
local eTemplate = eFrame.Template

ReplicatedStorage:WaitForChild("RoundHandler").SendHighlights.OnClientEvent:Connect(function(highlights: {Types.RoundHighlight}, events: {Types.UserFacingRoundEvent}, scores: {[Types.Participant]: Types.ParticipantScoring}, victors: Types.Role | Types.ClientParticipant)
	if victors.Kind == "ClientParticipant" then
		hFrame.Winners.Text = victors.Player.Name:upper().." WINS"
		hFrame.Winners.TextColor3 = LocalRoundInfo.GetRole(victors.Role).Colour
	else
		hFrame.Winners.Text = `THE {victors.Name:upper()}S WIN`
		hFrame.Winners.TextColor3 = victors.Colour
	end

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

	local startTime = LocalRoundInfo.GetStartTime()
	for _, v in events do
		local e = eTemplate:Clone()
		e.TextLabel.Text = v.Text
		e.Time.Text = API.ToRoundTime(startTime, v.Timestamp)
		e.Visible = true
		e.Name = "ActiveEvent"

		local icons = v.Icons
		if table.find(icons, "IncorrectKill") then
			e.IncorrectDamage.Visible = true
		end
		if table.find(icons, "FreeKill") then
			e.FreeKill.Visible = true
		end
		if table.find(icons, "SelfDefense") then
			e.SelfDefense.Visible = true
		end

		e.Parent = eFrame
	end
	
	UI:ToggleVisible(true)
end)

local currentTab = "Highlights"

local function showTab(tab)
	if currentTab == tab then
		return
	end
	UIAnimation.TransitionUIPage(page:FindFirstChild(currentTab) :: GuiObject, page:FindFirstChild(tab) :: GuiObject, UDim2.fromScale(0.5, 0.5))
	currentTab = tab
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