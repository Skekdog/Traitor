local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local manager = require(script.Parent.Parent)
local controls = require(ReplicatedFirst.ControlManager)

local event = script.Parent.Parent.UpdateThemeInstance
event.Event:Connect(manager.UpdateThemeInstance)

local orders = {
	Special = 4,
	Popup = 3,
	Buttons = 2,
	HUD = 1,
}

for _, layer in {"Popup", "HUD", "Special", "Buttons"} do
	local screenUi = Instance.new("ScreenGui")
	screenUi.Name = layer
	screenUi.IgnoreGuiInset = true
	screenUi.DisplayOrder = orders[layer]
	screenUi.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenUi.ResetOnSpawn = false
	screenUi.Parent = Players.LocalPlayer.PlayerGui
end

manager.RegisterUI(manager.UnregisteredUIs.Sidebar)
for _, object in manager.UnregisteredUIs:GetChildren() do
	if object:GetAttribute("DoNotRegister") then
		continue
	end
	manager.RegisterUI(object :: GuiObject)
end

controls.Register("Close UI", false, function()
	for _, v in manager.GetUIs("Popup") do
		if v.Visible and not v.NoClose then
			v:ToggleVisible(false)
			break
		end
	end
end)

ReplicatedStorage.ServerClient.OpenSettings.OnClientEvent:Connect(function()
	manager.WaitForUI("Settings"):ToggleVisible(true)
end)

local CASui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("ContextActionGui", math.huge) :: any
local CASFrame = CASui:WaitForChild("ContextButtonFrame")
CASFrame.Size = UDim2.fromScale(1, 1)
CASFrame.Position = UDim2.fromScale(0, 0)
CASui.DisplayOrder = 4
CASui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
CASui.ClipToDeviceSafeArea = false
CASui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension