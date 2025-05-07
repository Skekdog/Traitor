local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local KeybindHintManager = require(ReplicatedStorage.Shared.Controls.KeybindHintManager)
local SettingDefinitions = require(ReplicatedStorage.Shared.Settings.SettingDefinitions)

return function(name: string, value: SettingDefinitions.ControlValue): ()
	ControlManager.TryUpdateRegisteredAction(name, value)
	KeybindHintManager.TryUpdateKeybind(name, value)
end
