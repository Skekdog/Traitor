local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)
local ui = UIManager.WaitForUI("Sidebar")

local con: DynamicValue.Connection<Enum.PreferredInput>?

local AlwaysShowSidebar = {}

local function determineVisibility(alwaysShowSidebar: boolean): ()
    if alwaysShowSidebar then
        return ui:ToggleVisible(true)
    end

    local key = ControlManager.GetFirstKeyCode("Settings", true)
    if key == "" or key == "NONE" then
        return ui:ToggleVisible(true)
    end

    ui:ToggleVisible(false)
end

function AlwaysShowSidebar.Callback(name: string, value: boolean): ()
    if con then
        con:Disconnect()
        con = nil
    end

    determineVisibility(value)

    con = ControlManager.PreferredInput:Connect(function()
        determineVisibility(value)
    end)
end

function AlwaysShowSidebar.OnSettingsKeybindChanged(value: Settings.ControlValue): ()
    local alwaysShowSidebar = Settings.GetSetting("Always Show Sidebar") :: boolean
    determineVisibility(alwaysShowSidebar)
end

return AlwaysShowSidebar