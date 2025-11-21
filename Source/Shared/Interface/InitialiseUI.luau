local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local PlaceIDs = require(ReplicatedStorage.Shared.Places.PlaceIDs)
local ThemesManager = require(script.Parent.UILib.ThemesManager)

ThemesManager.UpdateTheme("Dark")

require(script.Parent.Welcome)
require(script.Parent.GameState.CalledToCorpse)
require(script.Parent.Chat.ChatPrefix)
require(script.Parent.Chat.QuickChat.QuickChatUI)
require(script.Parent.Chat.ChatWindow)
require(script.Parent.Chat.TeamChat)

for _, v in script.Parent.GameState:GetChildren() do
	if v:IsA("ModuleScript") then
		(require)(v)
	end
end

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

if game.PlaceId ~= PlaceIDs.MainPlace then
	local ui = UIManager.RegisterUI(UIManager.UnregisteredUIs.TestPlaceLabel) :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.TestPlaceLabel)}
	ui.Object.Text = "<br/>Traitor!" .. (if game.PlaceId == PlaceIDs.TestPlace then "Test Place" else "Labs")
	ui:ToggleVisible(true)
end

return nil