local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local QuickChat = require(script.Parent.QuickChat)
local Interaction = require(ReplicatedStorage.Shared.Actions.Interaction)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local PreferredInput = require(ReplicatedStorage.Shared.Controls.PreferredInput)
local ChatWindow = require(ReplicatedStorage.Shared.Interface.Chat.ChatWindow)
local QuickChatClient = require(script.Parent.QuickChatClient)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local ID_DURATION = 5
local AUTO_HIDE_AFTER = 5

local ui = (UIManager.WaitForUI("LeftArea").Object :: typeof(UIManager.UnregisteredUIs.LeftArea))["Quick Chat"]

type ChatButton = typeof(ui.ChatTemplate)

local id: Model?

local function chat(button: ChatButton): ()
	ui.Visible = false
	QuickChatClient.Chat(button.LayoutOrder, id)
end

local lastShow
ui:GetPropertyChangedSignal("Visible"):Connect(function()
	local thisShow = newproxy()
	lastShow = thisShow
	if not ui.Visible then
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(ui) then
			GuiService.SelectedObject = nil
		end

		for i = 1, 9 do
			ControlManager.Unregister("Quick Chat " .. i)
		end
		return
	end

	task.delay(AUTO_HIDE_AFTER, function()
		if lastShow == thisShow then
			ui.Visible = false
		end
	end)

	for _, v in ui:GetChildren() do
		if v:IsA("TextButton") and v.Name ~= "ChatTemplate" then
			v:Destroy()
		end
	end

	for i = 1, 9 do
		if QuickChat.Messages[i] then
			ControlManager.Register("Quick Chat " .. i, function()
				local button = ui:FindFirstChild(tostring(i))
				if not button or not button:IsA("TextButton") then
					return Enum.ContextActionResult.Pass
				end
				chat(button :: ChatButton)
				return Enum.ContextActionResult.Sink
			end)
		end
	end

	for i, v in QuickChat.Messages do
		local button = ui.ChatTemplate:Clone()
		button.LayoutOrder = i
		button.Name = tostring(i)
		button:SetAttribute("Control", "Quick Chat " .. i)
		button:AddTag("ControlHint")
		button.Parent = ui

		button.Activated:Connect(function()
			chat(button)
		end)
	end

	if not PreferredInput.PreferredInput().Name:find("Gamepad") then
		return
	end

	-- Timing issue...
	task.wait()
	task.wait()
	GuiService:Select(ui)
end)

ChatWindow.QuickChatButton.Activated:Connect(function()
	ui.Visible = not ui.Visible
end)

ControlManager.Register("Quick Chat", function()
	ui.Visible = not ui.Visible
	return Enum.ContextActionResult.Pass
end, Enum.ContextActionPriority.High.Value + 1)

RunService.Heartbeat:Connect(function()
	if not ui.Visible then
		return
	end

	local lastId = Interaction.GetLastId()
	id = if lastId.At + ID_DURATION < os.clock() then nil else lastId.Id
	for _, v in ui:GetChildren() do
		if v:IsA("TextButton") and v.Name ~= "ChatTemplate" then
			local button = v :: ChatButton
			button.Visible = true

			local baseMessage = QuickChat.Messages[tonumber(button.Name) or error("not a number")]
			button.TextLabel.Text = QuickChat.FormatMessage(baseMessage, id)
		end
	end
end)

return nil