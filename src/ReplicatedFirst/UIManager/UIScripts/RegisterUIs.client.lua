local ReplicatedStorage = game:GetService("ReplicatedStorage")
for _, v in script.Parent.Parent:FindFirstChild("UITypes"):GetChildren() do
	v.Parent = game:GetService("Players").LocalPlayer.PlayerGui
end

local manager = require(script.Parent.Parent)
local controls = require(game:GetService("ReplicatedFirst").ControlManager)

local event = script.Parent.Parent:FindFirstChild("UpdateThemeInstance")
event.Event:Connect(manager.UpdateThemeInstance)

for _, uiType in script.Parent.Parent:FindFirstChild("UnregisteredUIs"):GetChildren() do
	if uiType.ClassName ~= "Folder" then continue end
	for _, ui in uiType:GetChildren() do
		if ui:GetAttribute("DoNotRegister") then continue end
		manager.RegisterUI(ui.Name, uiType.Name, ui:GetAttribute("IgnoreInset"), ui, ui:GetAttribute("DisplayName"), ui:GetAttribute("PreventClose"))
	end
end

controls.Register("Close UI", false, function()
	local first
	for _, v in manager.GetUIs("UserTriggered") do
		if (v.Visible) and (not v.PreventClose) then
			first = v
			break
		end
	end
	if not first then
		for _, v in manager.GetUIs("Popup") do
			if (v.Visible) and (not v.PreventClose) then
				first = v
				break
			end
		end
	end
	if first then
		first:ToggleVisible(false)
	end
end)

ReplicatedStorage.ServerClient.OpenSettings.OnClientEvent:Connect(function()
	manager.WaitForUI("Settings"):ToggleVisible(true)
end)

local CASui: ScreenGui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("ContextActionGui", math.huge) :: any
local CASFrame = CASui:WaitForChild("ContextButtonFrame")
CASFrame.Size = UDim2.fromScale(1, 1)
CASFrame.Position = UDim2.fromScale(0, 0)
CASui.DisplayOrder = 4
CASui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
CASui.ClipToDeviceSafeArea = false
CASui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension