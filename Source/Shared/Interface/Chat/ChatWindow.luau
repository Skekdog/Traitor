local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local GetChatChannel = require(ReplicatedStorage.API.GetChatChannel)
local Types = require(ReplicatedStorage.API.Types)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local ChatWindow = {}

local MAX_LENGTH = 200
local AUTO_SCROLL_THRESHOLD = 5

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)

local ui = UIManager.RegisterUI(UIManager.UnregisteredUIs.Chat)
ui:ToggleVisible(true)

ChatWindow.TargetChannel = GetChatChannel("RBXGeneral")

local frame = ui.Object
ChatWindow.MessagesFrame = frame.Messages.ScrollingFrame
local messageTemplate = ChatWindow.MessagesFrame.MessageTemplate

local inputFrame = frame.Input
ChatWindow.InputBox = inputFrame.InputFrame.TextBox
local sendButton = inputFrame.SendButton

ChatWindow.QuickChatButton = inputFrame.QuickChatButton
ChatWindow.TeamChatButton = inputFrame.TeamChatButton

local selectedTeamChat = false
local teamChannel: TextChannel?
local function activateTeamChat(): ()
	if selectedTeamChat then
		assert(teamChannel, "Team channel not found")
		ChatWindow.TargetChannel = teamChannel
		ChatWindow.TeamChatButton.Icon.ImageTransparency = 0
	else
		ChatWindow.TargetChannel = GetChatChannel("RBXGeneral")
		ChatWindow.TeamChatButton.Icon.ImageTransparency = 0.75
	end
end

function ChatWindow.AllowTeamChat(role: Types.RoleDefinition, status: Types.ParticipantStatus | "Spectating"): ()
	local allow = (role.CanTeamChat and status == "Alive") or false
	ChatWindow.TeamChatButton.Icon.Visible = allow

	selectedTeamChat = false
	activateTeamChat()

	if not allow then
		teamChannel = nil
		return
	end

	ChatWindow.TeamChatButton.Icon.ImageTransparency = 0.75

	local foundTeamChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("Team_" .. role.Name)
	if foundTeamChannel:IsA("TextChannel") then
		teamChannel = foundTeamChannel
	end
end

ChatWindow.TeamChatButton.Activated:Connect(function()
	selectedTeamChat = not selectedTeamChat
	activateTeamChat()
end)

local function displayMessage(message: TextChatMessage): ()
	if message.Status ~= Enum.TextChatMessageStatus.Success and message.Status ~= Enum.TextChatMessageStatus.Sending then
		return
	end

	if message.Metadata:find("MUTED") then
		return
	end

	local isOutgoing = message.Status == Enum.TextChatMessageStatus.Sending

	if message.TextChannel.Name:sub(1, 5) == "Team_" then
		message.PrefixText = "<font color='#ff0000'>[TEAM]</font> " .. message.PrefixText
	end

	local originalLabel = ChatWindow.MessagesFrame:FindFirstChild(message.MessageId)
	if originalLabel and originalLabel:IsA("TextLabel") then
		originalLabel.Text = message.PrefixText .. " " .. message.Text
		originalLabel.TextTransparency = if isOutgoing then 0.5 else 0
		return
	end

	local messageBox = messageTemplate:Clone()
	messageBox.Name = message.MessageId
	messageBox.Text = message.PrefixText .. " " .. message.Text
	messageBox.TextTransparency = if isOutgoing then 0.5 else 0
	messageBox.Visible = true

	local shouldScroll = ((ChatWindow.MessagesFrame.AbsoluteCanvasSize.Y - ChatWindow.MessagesFrame.AbsoluteWindowSize.Y) - ChatWindow.MessagesFrame.CanvasPosition.Y) < AUTO_SCROLL_THRESHOLD

	messageBox.Parent = ChatWindow.MessagesFrame

	if shouldScroll then
		ChatWindow.MessagesFrame.CanvasPosition = Vector2.new(0, ChatWindow.MessagesFrame.AbsoluteCanvasSize.Y * 10) -- calculating the new position based on message size doesn't work correctly
	end
end

TextChatService.MessageReceived:Connect(displayMessage)
TextChatService.SendingMessage:Connect(displayMessage)

local function sendChat(): ()
	if ChatWindow.InputBox.Text == "" then
		return
	end
	ChatWindow.TargetChannel:SendAsync(ChatWindow.InputBox.Text)
	ChatWindow.InputBox.Text = ""
end

ChatWindow.InputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		sendChat()
	end
	selectedTeamChat = false
	activateTeamChat()
end)

ChatWindow.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
	local text = ChatWindow.InputBox.Text
	local isEmpty = text == ""
	sendButton.SendIcon.ImageColor3 = if isEmpty then Color3.fromRGB(178, 178, 178) else Color3.fromRGB(255, 255, 255)
	sendButton.SendIcon.ImageTransparency = if isEmpty then 0.5 else 0

	ChatWindow.InputBox.Text = text:sub(1, MAX_LENGTH)
end)

local defaultText = ChatWindow.InputBox.PlaceholderText

ChatWindow.InputBox.TextEditable = false
ChatWindow.InputBox.PlaceholderText = "Your Roblox settings prevent you from chatting."

task.spawn(function()
	if TextChatService:CanUserChatAsync(Players.LocalPlayer.UserId) then
		ChatWindow.InputBox.TextEditable = true
		ChatWindow.InputBox.PlaceholderText = defaultText
	end
end)

sendButton.Activated:Connect(function()
	sendChat()
	selectedTeamChat = false
	activateTeamChat()
end)

ControlManager.Register("Chat", function()
	ChatWindow.InputBox:CaptureFocus()
	return Enum.ContextActionResult.Pass
end)

ControlManager.Register("Team Chat", function()
	if not teamChannel then
		return Enum.ContextActionResult.Pass
	end
	selectedTeamChat = true
	activateTeamChat()
	ChatWindow.InputBox:CaptureFocus()
	return Enum.ContextActionResult.Pass
end)

return ChatWindow