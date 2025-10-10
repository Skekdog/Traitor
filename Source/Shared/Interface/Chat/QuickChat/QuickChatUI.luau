local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Interaction = require(ReplicatedStorage.Shared.Actions.Interaction)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local QuickChat = require(script.Parent.QuickChat)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local ID_DURATION = 5
local AUTO_HIDE_AFTER = 5

if not TextChatService:CanUserChatAsync(Players.LocalPlayer.UserId) then
	return nil
end

local ui = UIManager.RegisterUI(UIManager.UnregisteredUIs.QuickChat)

type ChatButton = typeof(ui.Object.ChatTemplate)

local function chat(button: ChatButton): ()
	ui:ToggleVisible(false)
	QuickChat.Chat(button.TextLabel.Text)
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
		if QuickChat.AvailableMessages[i] then
			ControlManager.Register("Quick Chat " .. i, function()
				local button = ui.Object:FindFirstChild(tostring(i))
				if not button or not button:IsA("TextButton") then
					return
				end
				chat(button :: ChatButton)
			end)
		end
	end

	for i, v in QuickChat.AvailableMessages do
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

RunService.Heartbeat:Connect(function()
	if not ui.Object.Visible then
		return
	end

	local id = if Interaction.LastId.At + ID_DURATION < os.clock() then nil else Interaction.LastId.Id
	for _, v in ui.Object:GetChildren() do
		if v:IsA("TextButton") and v.Name ~= "ChatTemplate" then
			local button = v :: ChatButton
			button.Visible = true

			local baseMessage = QuickChat.AvailableMessages[tonumber(button.Name) or error("not a number")]
			button.TextLabel.Text = QuickChat.FormatMessage(baseMessage, id)
		end
	end
end)

return nil