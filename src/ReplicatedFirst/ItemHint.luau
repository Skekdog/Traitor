local ControlManager = require(script.Parent.ControlManager)
local SettingsManager = require(script.Parent.SettingsManager)
local UIManager = require(script.Parent.UIManager)

local ui = UIManager.WaitForUI("ItemHint") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.ItemHint)}

return function(primary: string?, alternate: string?)
    if (not SettingsManager.GetSetting("Show Item Hints")) or (not primary and not alternate) then
        return ui:ToggleVisible(false)
    end

    local primaryFireKey = ControlManager.GetFirstKeyCode("Primary Fire")
    local alternateFireKey = ControlManager.GetFirstKeyCode("Alternate Fire")

    local text = ""
    if primary then
        text ..= `{primaryFireKey} {primary}`
    end
    text ..= "\n"
    if alternate then
        text ..= `{alternateFireKey} {alternate}`
    end

    ui.Object.Text = text

    ui:ToggleVisible(true)
end
