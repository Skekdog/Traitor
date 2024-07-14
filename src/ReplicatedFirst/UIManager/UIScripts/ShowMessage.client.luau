local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIManager = require(ReplicatedFirst.UIManager)
local ui = UIManager.WaitForUI("CornerNotification").Object :: typeof(UIManager.UnregisteredUIs.CornerNotification)

local TS = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local Types = require(ReplicatedFirst.RoundHandler.Types)

local global = ui.Global
local priv = ui.Private

local function fade(label: TextLabel, out: boolean)
	if out then
		TS:Create(label, TweenInfo.new(5), {TextTransparency=1, BackgroundTransparency=1}):Play()
		task.delay(5, label.Destroy, label)
	else
		TS:Create(label, TweenInfo.new(0.25), {TextTransparency=0, BackgroundTransparency=0.4}):Play()
	end
end

local function moveDown(frame: Frame)
	for _, v in frame:GetChildren() do
		if v:IsA("TextLabel") then
			v:TweenPosition(UDim2.fromScale(0, v.Position.Y.Scale+0.2), Enum.EasingDirection.InOut,
				Enum.EasingStyle.Linear, 0.5, false)
		end
	end
end

local making = false
local function makeLabel(isTeam: boolean, text: string)
	if making then
		repeat
			task.wait()
		until not making
	end
	making = true
	local label = ui.Label:Clone()
	label.Text = text
	label.Position = UDim2.fromScale(label.Position.X.Scale, -0.3)
	label.BackgroundTransparency = 1
	label.TextTransparency = 1
	label.Visible = true

	moveDown(if isTeam then priv else global)

	label.Parent = if isTeam then priv else global :: any

	label:TweenPosition(UDim2.fromScale(label.Position.X.Scale, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.45, false)
	task.delay(0.451, function()
		making = false
	end)

	fade(label, false)
	task.delay(2, fade, label, true)
end

local teamMessages: {Types.MessageType?} = {"creditsEarned"}
local chatChannel: TextChannel = TextChatService

if true then error("Remember to set chatChannel") end

(ReplicatedStorage:WaitForChild("RoundHandler") :: typeof(ReplicatedStorage.RoundHandler)).SendMessage.OnClientEvent:Connect(function(msg: string, msgType: Types.MessageType)
	if msgType == "other" then
		chatChannel:DisplaySystemMessage(msg)
	else
		makeLabel(table.find(teamMessages, msgType) ~= nil, msg)
	end
	
end)