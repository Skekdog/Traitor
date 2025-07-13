local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local PlaceIDs = require(ReplicatedStorage.Shared.Util.PlaceIDs)
local ThemesManager = require(script.Parent.UILib.ThemesManager)
ThemesManager.UpdateTheme("Dark")

require(script.Parent.Welcome)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

if game.PlaceId == PlaceIDs.TestPlace then
	UIManager.RegisterUI(UIManager.UnregisteredUIs.TestPlaceLabel):ToggleVisible(true)
end

return nil