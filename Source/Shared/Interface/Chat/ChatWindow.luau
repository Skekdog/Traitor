local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local GetChatChannel = require(ReplicatedStorage.API.GetChatChannel)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local ChatWindow = {}

local MAX_LENGTH = 200

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)

local ui = UIManager.RegisterUI(UIManager.UnregisteredUIs.Chat)
ui:ToggleVisible(true)

local RBXGeneral = GetChatChannel("RBXGeneral")

local frame = ui.Object
ChatWindow.MessagesFrame = frame.Messages.ScrollingFrame
local messageTemplate = ChatWindow.MessagesFrame.MessageTemplate

local inputFrame = frame.Input
ChatWindow.InputBox = inputFrame.InputFrame.TextBox
local sendButton = inputFrame.SendButton

TextChatService.MessageReceived:Connect(function(message)
	local isOutgoing = message.Status == Enum.TextChatMessageStatus.Sending

	local messageBox = messageTemplate:Clone()
	messageBox.Text = message.PrefixText .. " " .. message.Text
	messageBox.TextTransparency = if isOutgoing then 0.5 else 0
	messageBox.Visible = true

	messageBox.Parent = ChatWindow.MessagesFrame
end)

local function sendChat(): ()
	if ChatWindow.InputBox.Text == "" then
		return
	end
	RBXGeneral:SendAsync(ChatWindow.InputBox.Text)
	ChatWindow.InputBox.Text = ""
end

ChatWindow.InputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		sendChat()
	end
end)

ChatWindow.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
	local text = ChatWindow.InputBox.Text
	local isEmpty = text == ""
	sendButton.SendIcon.ImageColor3 = if isEmpty then Color3.fromRGB(178, 178, 178) else Color3.fromRGB(255, 255, 255)
	sendButton.SendIcon.ImageTransparency = if isEmpty then 0.5 else 0

	ChatWindow.InputBox.Text = text:sub(1, MAX_LENGTH)
end)

sendButton.Activated:Connect(sendChat)

ControlManager.Register("Chat", function()
	ChatWindow.InputBox:CaptureFocus()
	return Enum.ContextActionResult.Pass
end)

return nil