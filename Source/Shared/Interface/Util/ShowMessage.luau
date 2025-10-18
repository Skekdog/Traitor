local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local FullParse = require(ReplicatedStorage.Shared.ParseString.FullParse)
local UIAnimation = require(script.Parent.Parent.UILib.UIAnimation)
local UIManager = require(script.Parent.Parent.UILib.UIManager)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)

local ui = UIManager.WaitForUI("CornerNotification").Object :: typeof(UIManager.UnregisteredUIs.CornerNotification)

type CornerNotificationLabel = typeof(ui.Label)

local global = ui.Global
local priv = ui.Private

local function fade(label: CornerNotificationLabel, out: boolean)
	if out then
		local animate = Settings.GetSetting("Animate UI Transitions")
		if animate then
			TweenService:Create(label, TweenInfo.new(5), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
			TweenService:Create(label.UIStroke, TweenInfo.new(5), {Transparency = 1}):Play()
		end
		task.delay(5, label.Destroy, label)
	else
		UIAnimation.Animate(label, TweenInfo.new(0.25), {TextTransparency = 0, BackgroundTransparency = 0.4})
		TweenService:Create(label.UIStroke, TweenInfo.new(5), {Transparency = 0}):Play()
	end
end

local function moveDown(frame: Frame)
	for _, v in frame:GetChildren() do
		if v:IsA("TextLabel") then
			local target = v:GetAttribute("TargetPosition") :: UDim2 + UDim2.fromOffset(0, v.AbsoluteSize.Y + 10)
			v:SetAttribute("TargetPosition", target)
			UIAnimation.Animate(v, TweenInfo.new(0.5), { Position = target})
		end
	end
end

local function makeLabel(isTeam: boolean, text: string)
	local label = ui.Label:Clone()
	label.Text = text
	label:SetAttribute("TargetPosition", UDim2.fromOffset(label.AbsolutePosition.X, 0))
	label.Position = UDim2.fromOffset(label.AbsolutePosition.X, -label.AbsoluteSize.Y * 2)
	label.BackgroundTransparency = 1
	label.TextTransparency = 1
	label.Visible = true

	moveDown(if isTeam then priv else global)

	label.Parent = if isTeam then priv else global :: any

	UIAnimation.Animate(label, TweenInfo.new(0.45), { Position = UDim2.fromScale(label.Position.X.Scale, 0) })

	fade(label, false)
	task.delay(2, fade, label, true)
end

local chatChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral") :: TextChannel

return function(msg: string, kind: Types.MessageKind)
	msg = FullParse(msg)
	if kind == "Chat" then
		chatChannel:DisplaySystemMessage(msg)
	else
		makeLabel(kind == "Team", msg)
	end
end