local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AlwaysShowSidebar = require(script.Parent.AlwaysShowSidebar)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local KeybindHintManager = require(ReplicatedStorage.Shared.Controls.KeybindHintManager)
local SettingDefinitions = require(ReplicatedStorage.Shared.Settings.SettingDefinitions)

return function(name: string, value: SettingDefinitions.ControlValue): ()
	ControlManager.TryUpdateRegisteredAction(name, value)
	KeybindHintManager.TryUpdateKeybind(name)
	if name == "Settings" then
		AlwaysShowSidebar.OnSettingsKeybindChanged(value)
	end
end
