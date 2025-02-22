local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local UIAnimation = require(script.Parent.UIAnimation)
local UIManager = require(script.Parent.UIManager)
local Types = require(ReplicatedStorage.RoundRule.Types)
local Settings = require(ReplicatedStorage.Settings.Settings)

local ui = UIManager.WaitForUI("CornerNotification").Object :: typeof(UIManager.UnregisteredUIs.CornerNotification)

local global = ui.Global
local priv = ui.Private

local function fade(label: TextLabel, out: boolean)
	if out then
		local animate = Settings.GetSetting("Animate UI Transitions")
		if animate then
			TweenService:Create(label, TweenInfo.new(5), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
		end
		task.delay(5, label.Destroy, label)
	else
		UIAnimation.Animate(label, TweenInfo.new(0.25), {TextTransparency = 0, BackgroundTransparency = 0.4})
	end
end

local function moveDown(frame: Frame)
	for _, v in frame:GetChildren() do
		if v:IsA("TextLabel") then
			local target = v:GetAttribute("TargetPosition") :: UDim2 + UDim2.fromScale(0, 0.2)
			v:SetAttribute("TargetPosition", target)
			UIAnimation.Animate(v, TweenInfo.new(0.5), { Position = target})
		end
	end
end

local function makeLabel(isTeam: boolean, text: string)
	local label = ui.Label:Clone()
	label.Text = text
	label:SetAttribute("TargetPosition", UDim2.fromScale(label.Position.X.Scale, 0))
	label.Position = UDim2.fromScale(label.Position.X.Scale, -0.3)
	label.BackgroundTransparency = 1
	label.TextTransparency = 1
	label.Visible = true

	moveDown(if isTeam then priv else global)

	label.Parent = if isTeam then priv else global

	UIAnimation.Animate(label, TweenInfo.new(0.45), { Position = UDim2.fromScale(label.Position.X.Scale, 0) })

	fade(label, false)
	task.delay(2, fade, label, true)
end

local chatChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral") :: TextChannel

return function(msg: string, kind: Types.MessageKind)
	if kind == "Chat" then
		chatChannel:DisplaySystemMessage(msg)
	else
		makeLabel(kind == "Team", msg)
	end
end