local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsAdmin = require(script.Parent.IsAdmin)
local RelaxedPermissions = require(script.Parent.RelaxedPermissions)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local Exec = require(ReplicatedStorage.Shared.DevTools.Exec)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local didConnect = false
local console: (UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Console)})?
RelaxedPermissions.TemporaryPermissions:Connect(function(perms)
	if RelaxedPermissions.HasRelaxedPermissions(Players.LocalPlayer) or IsAdmin(Players.LocalPlayer) then
		if console then
			return
		end

		console = UIManager.RegisterUI(UIManager.UnregisteredUIs.Console) :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Console)}
		assert(console)

		ControlManager.Register("Console", function()
			console:ToggleVisible()

			if console.Visible then
				console.Object.Input:CaptureFocus()
			end

			return Enum.ContextActionResult.Sink
		end)

		local object = console.Object

		if not didConnect then
			didConnect = true
			object.Input.FocusLost:Connect(function(enterPressed)
				if not enterPressed then
					return
				end

				object.Output.Text = Exec.ClientExecute(object.Input.Text)
			end)

			object.Input:GetPropertyChangedSignal("Text"):Connect(function()
				object.Output.Text = ""
			end)
		end
	elseif console then
		console:Unregister()
	end
end, true)