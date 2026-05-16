local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local Gamepass = require(ReplicatedStorage.Shared.Monetisation.Gamepass)
local GamepassIDs = require(ReplicatedStorage.Shared.Monetisation.GamepassIDs)

local remote = GetRemote("SoundPlayer", ReplicatedStorage)

local ui = UIManager.WaitForUI("Sound Player") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs["Sound Player"])}

local textBox = ui.Object.TextBox
ui.Object:GetPropertyChangedSignal("Visible"):Connect(function()
	textBox.Text = ""
	if ui.Object.Visible then
		textBox:CaptureFocus()
	end
end)

ui.Object.TextBox.FocusLost:Connect(function(enterPressed): ()
	ui:ToggleVisible(false)
	if not enterPressed then
		return
	end

	if not Gamepass.PromptIfNotOwned(GamepassIDs["Sound Player"], Players.LocalPlayer) then
		return
	end

	local id = tonumber(textBox.Text)
	if not id then
		return
	end

	remote:FireServer(id)
end)

return nil