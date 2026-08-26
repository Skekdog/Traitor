local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CustomActions = require(ReplicatedStorage.API.CustomActions)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local ui = UIManager.WaitForUI<<typeof(UIManager.UnregisteredUIs["Action Picker"])>>("Action Picker")
local actionUi = UIManager.WaitForUI<<typeof(UIManager.UnregisteredUIs.LeftArea)>>("LeftArea").Object.Actions

local menuPickerUI = UIManager.WaitForUI("Menu Picker")
local inventoryUI = UIManager.WaitForUI("Inventory")

local function createButton(name: string, action: string): ()
	local button = ui.Object.ButtonTemplate:Clone()
	button.Name = action
	button.Text = action

	button.Activated:Connect(function()
		ui:ToggleVisible(false)
		CustomActions.Trigger(action)
	end)

	button.Visible = true
	button.Parent = ui.Object
end

actionUi.ChildAdded:Connect(function(child)
	local textLabel = child:FindFirstChildWhichIsA("TextLabel")
	if textLabel then
		createButton(child.Name, textLabel.Text)
	end
end)

actionUi.ChildRemoved:Connect(function(child)
	local entry = ui.Object:FindFirstChild(child.Name)
	if entry then
		entry:Destroy()
	end
end)

for _, action in actionUi:GetChildren() do
	if action:IsA("GuiObject") and action.Name ~= "ButtonTemplate" then
		local textLabel = action:FindFirstChildWhichIsA("TextLabel")
		if textLabel then
			createButton(action.Name, textLabel.Text)
		end
	end
end

ui.Object:GetPropertyChangedSignal("Visible"):Connect(function()
	if not ControlManager.PreferredInput().Name:find("Gamepad") then
		return
	end

	if ui.Object.Visible then
		menuPickerUI:ToggleVisible(false)
		if inventoryUI.Object:GetAttribute("TransitionDirection") == nil then
			inventoryUI:ToggleVisible(false)
		end

		GuiService:Select(ui.Object)
	elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(ui.Object) then
		GuiService.SelectedObject = nil
	end
end)

return nil