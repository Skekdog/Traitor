local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(script.Parent.Settings)
local SettingsUI = require(script.Parent.SettingsUI)

task.spawn(function()
	local tags: {string} = ReplicatedStorage.Remotes.ClientServer.GetChatTags:InvokeServer()

	local definition = Settings.GetDefinition("Chat Tag")
	assert(definition and definition.Kind == "Choice")

	table.insert(tags, 1, "None")
	definition.PossibleValues = tags

	local value = Settings.GetSetting(definition.Name) :: string
	if not table.find(tags, value) then
		value = "None"
	end

	Settings.SetSetting(definition.Name, value)

	SettingsUI.RemoveButton(definition)
	SettingsUI.AddButton(definition, value)
end)


return nil