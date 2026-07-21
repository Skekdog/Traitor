local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsAdmin = require(script.Parent.IsAdmin)
local RelaxedPermissions = require(script.Parent.RelaxedPermissions)
local Message = require(ReplicatedStorage.API.Interface.Message)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local mouseUnlock: UIManager.UI?

RelaxedPermissions.TemporaryPermissions:Connect(function(perms)
	if RelaxedPermissions.HasRelaxedPermissions(Players.LocalPlayer) or IsAdmin(Players.LocalPlayer) then
		if true and mouseUnlock then
			return
		end

		mouseUnlock = UIManager.TryGetUI("MouseUnlock") or UIManager.RegisterUI(UIManager.UnregisteredUIs.MouseUnlock)
		assert(mouseUnlock)

		ControlManager.Register("Mouse Unlock", function()
			mouseUnlock:ToggleVisible()
			Message.Screen(if mouseUnlock.Visible then "Mouse unlocked." else "Mouse locked.", "Info")

			return Enum.ContextActionResult.Pass
		end)
	end
end, true)

return nil