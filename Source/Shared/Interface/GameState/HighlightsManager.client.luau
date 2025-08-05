local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ToRoundTime = require(ReplicatedStorage.Shared.Grammar.ToRoundTime)
local UIAnimation = require(ReplicatedStorage.Shared.Interface.UILib.UIAnimation)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local Role = require(ReplicatedStorage.Shared.RoundRule.Role)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local UI = UIManager.WaitForUI("Highlights") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Highlights)}
local page = UI.Object.Page

local highlightsPage, eventsPage, scoresPage = page.Highlights, page.Events, page.Scores
local eventTemplate = eventsPage.Template

local function calculateTotalScore(score: Types.ScoreTable): number
	local total = 0
	for _, v in score do
		assert(v)
		total += v
	end
	return total
end

local minimisedScoreSize = scoresPage.AbsoluteSize.Y * 0.075
repeat
	minimisedScoreSize = scoresPage.AbsoluteSize.Y * 0.075
	task.wait()
until minimisedScoreSize > 0

-- note: the "Nothing here yet..." label is cleared by populateEvents and populateScores in the destroy children section, not explicitly. It only needs to exist when the game first loads.
local function populateEvents(): ()
	for _, v in eventsPage:GetChildren() do
		if v.ClassName ~= "UIListLayout" and v.Name ~= "Template" and v.ClassName ~= "UIPadding" then
			v:Destroy()
		end
	end

	local roundStartTime = LocalRoundInfo.StartTime() or error("Round start time not found")
	for _, v in LocalRoundInfo.GetOrderedRoundEvents() do
		local event = eventTemplate:Clone()
		event.Name = v.Description
		event.TextLabel.Text = v.Description
		event.Time.Text = ToRoundTime(roundStartTime, v.Timestamp)

		if v.WasCorrectKill == false then
			event.IncorrectDamage.Visible = true
		end

		if v.WasFreeKill == true then
			event.FreeKill.Visible = true
		end

		if v.WasSelfDefense == true then
			event.SelfDefense.Visible = true
		end

		event.Visible = true
		event.Parent = eventsPage
	end
end

local function populateScores(): ()
	for _, v in scoresPage:GetChildren() do
		if v.ClassName ~= "UIListLayout" and v.Name ~= "Template" and v.ClassName ~= "UIPadding" then
			v:Destroy()
		end
	end

	for i, v in LocalRoundInfo.GetPlayerScores() do
		local scoreFrame = scoresPage.Template:Clone()
		scoreFrame.Size = UDim2.new(1, 0, 0, minimisedScoreSize)

		local usernameLabel = scoreFrame.Username
		local totalLabel = scoreFrame.Total
		local scoreList = scoreFrame.Score

		local openedSize = (minimisedScoreSize / 3) * 10
		local scoreListSize = (minimisedScoreSize / 3) * 7

		scoreList.Position = UDim2.fromOffset(0, minimisedScoreSize)
		usernameLabel.Size = UDim2.new(0.5, 0, 0, minimisedScoreSize)
		totalLabel.Size = UDim2.new(0.5, 0, 0, minimisedScoreSize)

		local role = LocalParticipantInfo.GetParticipant(i).Role()
		if role then
			usernameLabel.Text = role:GetFormattedString("@" .. i)
		else
			usernameLabel.Text = "@" .. i
		end

		local total = calculateTotalScore(v)
		totalLabel.Text = total.." Total"

		scoreFrame.LayoutOrder = -total

		for reason, value in v do
			assert(value)
			local reasonFrame = scoreList.Template:Clone()
			reasonFrame.Text = reason:gsub("_", " ") .. (if value > 0 then " +" else " -") .. math.abs(value)
			reasonFrame.Name = reason
			reasonFrame.Visible = true
			reasonFrame.Parent = scoreList
		end

		scoreFrame.Name = "ScoreFrame"
		scoreFrame.Visible = true
		scoreFrame.Parent = scoresPage

		scoreFrame.Activated:Connect(function()
			local open = not scoreFrame:GetAttribute("Open")
			scoreFrame:SetAttribute("Open", open)

			local targetSize = if open then openedSize else minimisedScoreSize
			local scoreListTarget = if open then scoreListSize else 0

			local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Exponential)
			UIAnimation.Animate(scoreFrame, tweenInfo, {
				Size = UDim2.new(1, 0, 0, targetSize)
			})

			UIAnimation.Animate(scoreList, tweenInfo, {
				Size = UDim2.new(1, 0, 0, scoreListTarget)
			})
		end)
	end
end

local function setHighlights(): ()
	local highlights = LocalRoundInfo.GetHighlights()

	table.sort(highlights, function(highlight1, highlight2)
		return highlight1.Priority > highlight2.Priority --todo: i remember that something like this errored before, but i checked with lune and it didn't. see what's up, this might not work still.
	end)

	for i, highlight in highlights do
		if i > 5 then
			break
		end

		local frame = highlightsPage.Highlights:FindFirstChild("Highlight" .. tostring(i)) :: typeof(highlightsPage.Highlights.Highlight1)

		frame.Description.Text = highlight.Description
		frame.Highlight.Text = highlight.Title
	end
end

local function setWinnerText(): ()
	local winner, winnerKind = LocalRoundInfo.Winner(), LocalRoundInfo.WinnerKind()
	assert(winner and winnerKind, "No winner")

	local gamemode = assert(LocalRoundInfo.Gamemode(), "No gamemode")
	local winnerRole = if winnerKind == "Participant" then LocalParticipantInfo.GetParticipant(winner).Role() else Role.fromDefinition(gamemode.Roles[winner])

	if winnerKind == "Participant" then
		highlightsPage.Winners.Text = winnerRole:GetFormattedString(winner) .. " wins!"
	else
		highlightsPage.Winners.Text = `The {winnerRole:GetFormattedString(winner .. "s")} win!`
	end
end

LocalRoundInfo.Phase:Connect(function(phase)
	if phase ~= "Highlights" then
		return
	end

	setWinnerText()

	populateEvents()
	populateScores()
	setHighlights()

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

tabs.EventsButton.MouseButton1Click:Connect(function() showTab("Events") end)
tabs.HighlightsButton.MouseButton1Click:Connect(function() showTab("Highlights") end)
tabs.ScoresButton.MouseButton1Click:Connect(function() showTab("Scores") end)

showTab("Highlights")

local function onRoundEndMusicChildAdded(child: Instance)
	if child:IsA("Sound") then
		child.SoundGroup = SoundService.RoundEndMusic
		highlightsPage.Music.Text.Text = child.Name
	end
end

SoundService.RoundEndMusic.ChildAdded:Connect(onRoundEndMusicChildAdded)
for _, v in SoundService.RoundEndMusic:GetChildren() do
	onRoundEndMusicChildAdded(v)
end

local muteMusicButton = highlightsPage.Music.Mute 

local pause = false
muteMusicButton.MouseButton1Click:Connect(function()
	pause = not pause
	SoundService.RoundEndMusic.Volume = if pause then 0 else 1
	muteMusicButton.Image = `rbxasset://textures/ui/VoiceChat/SpeakerLight/{if pause then "Muted@3x" else "Unmuted0@3x"}.png`
end)