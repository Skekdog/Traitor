local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local QuickChat = require(script.Parent.QuickChat)
local Interaction = require(ReplicatedStorage.Shared.Actions.Interaction)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local ChatWindow = require(ReplicatedStorage.Shared.Interface.Chat.ChatWindow)
local QuickChatClient = require(script.Parent.QuickChatClient)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local ID_DURATION = 5
local AUTO_HIDE_AFTER = 5

local ui = UIManager.RegisterUI(UIManager.UnregisteredUIs["Quick Chat"])

type ChatButton = typeof(ui.Object.ChatTemplate)

local id: Model?

local function chat(button: ChatButton): ()
	ui:ToggleVisible(false)
	QuickChatClient.Chat(button.LayoutOrder, id)
end

local lastShow
ui.Object:GetPropertyChangedSignal("Visible"):Connect(function()
	local thisShow = newproxy()
	lastShow = thisShow
	if not ui.Object.Visible then
		for i = 1, 9 do
			ControlManager.Unregister("Quick Chat " .. i)
		end
		return
	end

	task.delay(AUTO_HIDE_AFTER, function()
		if lastShow == thisShow then
			ui:ToggleVisible(false)
		end
	end)

	for _, v in ui.Object:GetChildren() do
		if v:IsA("TextButton") and v.Name ~= "ChatTemplate" then
			v:Destroy()
		end
	end

	for i = 1, 9 do
		if QuickChat.Messages[i] then
			ControlManager.Register("Quick Chat " .. i, function()
				local button = ui.Object:FindFirstChild(tostring(i))
				if not button or not button:IsA("TextButton") then
					return Enum.ContextActionResult.Pass
				end
				chat(button :: ChatButton)
				return Enum.ContextActionResult.Sink
			end)
		end
	end

	for i, v in QuickChat.Messages do
		local button = ui.Object.ChatTemplate:Clone()
		button.LayoutOrder = i
		button.Name = tostring(i)
		button:SetAttribute("Control", "Quick Chat " .. i)
		button:AddTag("ControlHint")
		button.Parent = ui.Object

		button.Activated:Connect(function()
			chat(button)
		end)
	end
end)

ChatWindow.QuickChatButton.Activated:Connect(function()
	ui:ToggleVisible()
end)

RunService.Heartbeat:Connect(function()
	if not ui.Object.Visible then
		return
	end

	local lastId = Interaction.GetLastId()
	id = if lastId.At + ID_DURATION < os.clock() then nil else lastId.Id
	for _, v in ui.Object:GetChildren() do
		if v:IsA("TextButton") and v.Name ~= "ChatTemplate" then
			local button = v :: ChatButton
			button.Visible = true

			local baseMessage = QuickChat.Messages[tonumber(button.Name) or error("not a number")]
			button.TextLabel.Text = QuickChat.FormatMessage(baseMessage, id)
		end
	end
end)

return nil