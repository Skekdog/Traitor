local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlManager = require(ReplicatedStorage.ControlManager)
local KeybindHintManager = require(ReplicatedStorage.KeybindHintManager)
local SettingDefinitions = require(ReplicatedStorage.Settings.SettingDefinitions)

return function(name: string, value: SettingDefinitions.ControlValue): ()
	ControlManager.TryUpdateRegisteredAction(name, value)
	KeybindHintManager.TryUpdateKeybind(name, value)
end
