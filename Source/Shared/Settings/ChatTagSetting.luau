local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(script.Parent.Settings)
local SettingsUI = require(script.Parent.SettingsUI)

local tags: {string} = ReplicatedStorage.Remotes.ClientServer.GetChatTags:InvokeServer()

local definition = Settings.GetDefinition("Chat Tag")
assert(definition and definition.Kind == "Choice")

table.insert(tags, 1, "None")
definition.PossibleValues = tags

SettingsUI.RemoveButton(definition)
SettingsUI.AddButton(definition, Settings.GetSetting(definition.Name))

return nil