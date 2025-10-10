local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Interaction = require(ReplicatedStorage.Shared.Actions.Interaction)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local QuickChat = require(script.Parent.QuickChat)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local ID_DURATION = 5

local ui = UIManager.WaitForUI("QuickChat") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.QuickChat)}

local function chat(button: TextButton): ()
	ui:ToggleVisible(false)
	QuickChat.Chat(button.Text)
end

ui.Object:GetPropertyChangedSignal("Visible"):Connect(function()
	if not ui.Object.Visible then
		for i = 1, 9 do
			ControlManager.Unregister("Quick Chat " .. i)
		end
		return
	end

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
				chat(button)
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
			v.Visible = true

			local baseMessage = QuickChat.AvailableMessages[tonumber(v.Name) or error("not a number")]
			v.Text = QuickChat.FormatMessage(baseMessage, id)
		end
	end
end)

return nil