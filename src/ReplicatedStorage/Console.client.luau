local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlManager = require(script.Parent.ControlManager)
local IsAdmin = require(script.Parent.IsAdmin)
local UIManager = require(script.Parent.UIManager)

if not IsAdmin(Players.LocalPlayer) then
	return
end

local console = UIManager.RegisterUI(UIManager.UnregisteredUIs.Console) :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Console)}

ControlManager.Register("Console", function()
	console:ToggleVisible()

	if console.Visible then
		console.Object.Input:CaptureFocus()
	end

	return Enum.ContextActionResult.Sink
end)

local object = console.Object

object.Input.FocusLost:Connect(function(enterPressed)
	if not enterPressed then
		return
	end

	object.Output.Text = ReplicatedStorage.ClientServer.Exec:InvokeServer(object.Input.Text)
end)

object.Input:GetPropertyChangedSignal("Text"):Connect(function()
	object.Output.Text = ""
end)
