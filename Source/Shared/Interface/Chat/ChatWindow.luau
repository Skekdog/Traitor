local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local GetChatChannel = require(ReplicatedStorage.API.GetChatChannel)
local Message = require(ReplicatedStorage.API.Interface.Message)
local Types = require(ReplicatedStorage.API.Types)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local SoundPlayerClient = require(ReplicatedStorage.Shared.Interface.GameState.SoundPlayerClient)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)

local ChatWindow = {}

local MAX_LENGTH = 200
local MAX_MESSAGES = 100
local AUTO_SCROLL_THRESHOLD = 5

local QUICKCHAT_COLOUR = Color3.fromRGB(191, 251, 255)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)

local targetChannel = GetChatChannel("RBXGeneral")

local frame = (UIManager.WaitForUI("LeftArea").Object :: typeof(UIManager.UnregisteredUIs.LeftArea)).Chat.Frame
frame.Visible = true

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
		targetChannel = teamChannel
		ChatWindow.TeamChatButton.Icon.ImageTransparency = 0
	else
		targetChannel = GetChatChannel("RBXGeneral")
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
	-- We can't make the button itself non-visible because that messes with the layout
	if not ChatWindow.TeamChatButton.Icon.Visible then
		return
	end

	selectedTeamChat = not selectedTeamChat
	activateTeamChat()
end)

local messages: {GuiObject} = {}

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

	local colouredText = if message.Metadata:find("QuickChat") then
		`<font color='#{QUICKCHAT_COLOUR:ToHex()}'>{message.Text}</font>`
	else
		message.Text

	local finalText = message.PrefixText .. " " .. colouredText

	local originalLabel = ChatWindow.MessagesFrame:FindFirstChild(message.MessageId)
	if originalLabel and originalLabel:IsA("TextLabel") then
		originalLabel.Text = finalText
		originalLabel.TextTransparency = if isOutgoing then 0.5 else 0
		return
	end

	local messageBox = messageTemplate:Clone()
	messageBox.Name = message.MessageId
	messageBox.Text = finalText
	messageBox.TextTransparency = if isOutgoing then 0.5 else 0
	messageBox.Visible = true

	local shouldScroll = ((ChatWindow.MessagesFrame.AbsoluteCanvasSize.Y - ChatWindow.MessagesFrame.AbsoluteWindowSize.Y) - ChatWindow.MessagesFrame.CanvasPosition.Y) < AUTO_SCROLL_THRESHOLD

	messageBox.Parent = ChatWindow.MessagesFrame

	table.insert(messages, messageBox)
	if #messages > MAX_MESSAGES then
		local oldMessage = messages[1]
		table.remove(messages, 1)
		oldMessage:Destroy()
	end

	local totalHeight = 0
	for _, message in messages do
		totalHeight += message.AbsoluteSize.Y
	end

	ChatWindow.MessagesFrame.CanvasSize = UDim2.fromOffset(0, totalHeight)

	if shouldScroll then
		ChatWindow.MessagesFrame.CanvasPosition = Vector2.new(0, ChatWindow.MessagesFrame.AbsoluteCanvasSize.Y * 10) -- calculating the new position based on message size doesn't work correctly
	end
end

TextChatService.MessageReceived:Connect(displayMessage)
TextChatService.SendingMessage:Connect(displayMessage)

local function trySoundPlayer(message: string): boolean
	if not Settings.GetSetting("Enable Sound Player Command") then
		return false
	end

	if message:sub(1, 2) ~= "s/" then
		return false
	end

	local id = tonumber(message:sub(3))
	if not id then
		return false
	end

	-- 75% chance to not work because don't use the chat command.
	if math.random() > 0.75 then
		Message.Chat("Failed to play sound. Try using the GUI instead.")
		return true
	end

	Message.Chat("Please use the GUI instead.")
	SoundPlayerClient.TryPlay(id)

	return true
end

local function sendChat(): ()
	local message = ChatWindow.InputBox.Text
	if message == "" then
		return
	end

	if trySoundPlayer(message) then
		ChatWindow.InputBox.Text = ""
		return
	end

	targetChannel:SendAsync(message)
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
	sendButton.SendIcon.TextColor3 = if isEmpty then Color3.fromRGB(178, 178, 178) else Color3.fromRGB(255, 255, 255)
	sendButton.SendIcon.TextTransparency = if isEmpty then 0.5 else 0

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
	task.spawn(function()
		task.wait()
		ChatWindow.InputBox:CaptureFocus()
	end)

	return Enum.ContextActionResult.Pass
end)

ControlManager.Register("Team Chat", function()
	if not teamChannel then
		return Enum.ContextActionResult.Pass
	end
	selectedTeamChat = true
	activateTeamChat()

	task.spawn(function()
		task.wait()
		ChatWindow.InputBox:CaptureFocus()
	end)

	return Enum.ContextActionResult.Pass
end)

return table.freeze(ChatWindow)