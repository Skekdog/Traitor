local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)

local ui = UIManager.WaitForUI("ItemHint") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.ItemHint)}

return function(primary: string?, alternate: string?)
    if (not Settings.GetSetting("Item Hints")) or (not primary and not alternate) then
        return ui:ToggleVisible(false)
    end

    ui.Object.Primary.HintLabel.Text = primary or ""
    ui.Object.Alternate.HintLabel.Text = alternate or ""

    ui.Object.Primary.Visible = not not primary
    ui.Object.Alternate.Visible = not not alternate

    ui:ToggleVisible(true)
end
