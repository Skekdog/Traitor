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

local function calculateTotalScore(score: Types.ParticipantScoring): number
	local total = 0
	for _, v in score do
		total += v
	end
	return total
end

ReplicatedStorage:WaitForChild("RoundHandler").SendHighlights.OnClientEvent:Connect(function(highlights: {Types.RoundHighlight}, events: {Types.UserFacingRoundEvent}, scores: {[Types.FormattedUsername]: Types.ParticipantScoring}, victors: Types.Role | Types.ClientParticipant)
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
		if v.ClassName ~= "UIListLayout" and v.Name ~= "Template" and v.ClassName ~= "UIPadding" then
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

	for i, v in scores do
		local scoreFrame = sFrame.Template:Clone()
		scoreFrame.Size = UDim2.fromScale(1, 0.075)

		local usernameLabel = scoreFrame.Username
		local totalLabel = scoreFrame.Total
		local scoreList = scoreFrame.Score

		local minimisedSize = sFrame.AbsoluteSize.Y * 0.075
		repeat
			minimisedSize = sFrame.AbsoluteSize.Y * 0.075
		until minimisedSize > 0

		local openedSize = (minimisedSize / 3) * 10
		local scoreListSize = (minimisedSize / 3) * 7

		scoreList.Position = UDim2.fromOffset(0, minimisedSize)
		usernameLabel.Size = UDim2.new(0.5, 0, 0, minimisedSize)
		totalLabel.Size = UDim2.new(0.5, 0, 0, minimisedSize)

		usernameLabel.Text = "@"..i
		totalLabel.Text = calculateTotalScore(v).." Total"

		scoreFrame.Visible = true
		scoreFrame.Parent = sFrame
		
		scoreFrame.MouseButton1Click:Connect(function()
			local open = not scoreFrame:GetAttribute("Open")
			scoreFrame:SetAttribute("Open", open)

			local targetSize = if open then openedSize else minimisedSize
			local scoreListTarget = if open then scoreListSize else 0

			local tweenInfo = TweenInfo.new(0.2)
			UIAnimation.Animate(scoreFrame, tweenInfo, {
				Size = UDim2.new(1, 0, 0, targetSize)
			})

			UIAnimation.Animate(scoreList, tweenInfo, {
				Size = UDim2.new(1, 0, 0, scoreListTarget)
			})
		end)
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
local tabs = UI.Object.Tabs

local function showTab(tab: string)
	UIAnimation.TransitionUnderline(tabs.Underline, (tabs :: any)[tab.."Button"])
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

tabs.EventsButton.MouseButton1Click:Connect(function() showTab("Events") end)
tabs.HighlightsButton.MouseButton1Click:Connect(function() showTab("Highlights") end)
tabs.ScoresButton.MouseButton1Click:Connect(function() showTab("Scores") end)

showTab("Highlights")