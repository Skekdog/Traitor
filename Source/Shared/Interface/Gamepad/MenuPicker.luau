local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local ui = UIManager.WaitForUI<<typeof(UIManager.UnregisteredUIs["Menu Picker"])>>("Menu Picker")
local sidebarUi = UIManager.WaitForUI<<typeof(UIManager.UnregisteredUIs.Sidebar)>>("Sidebar")

-- These will be at the top of the list. Last item in the array is first
local additionalMenus = {
	"Sound Player",
	"Action Picker",
}

local function createButton(menu: string, layoutOrder: number?): ()
	local button = ui.Object.ButtonTemplate:Clone()
	button.Name = menu
	button.Text = menu

	button.Activated:Connect(function()
		ui:ToggleVisible(false)
		UIManager.GetUI(menu):ToggleVisible(true)
	end)

	button.LayoutOrder = layoutOrder or 1
	button.Visible = true
	button.Parent = ui.Object
end

sidebarUi.Object.ChildAdded:Connect(function(child)
	createButton(child.Name)
end)

sidebarUi.Object.ChildRemoved:Connect(function(child)
	local entry = ui.Object:FindFirstChild(child.Name)
	if entry then
		entry:Destroy()
	end
end)

for _, menu in sidebarUi.Object:GetChildren() do
	if menu:IsA("GuiObject") and menu.Name ~= "Entry" then
		createButton(menu.Name)
	end
end

for i, menu in additionalMenus do
	createButton(menu, -i)
end

ui.Object:GetPropertyChangedSignal("Visible"):Connect(function()
	if ui.Object.Visible then
		GuiService:Select(ui.Object)
	elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(ui.Object) then
		GuiService.SelectedObject = nil
	end
end)

return nil