local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local UIManager = require(script.Parent.UILib.UIManager)

local ui = UIManager.WaitForUI("Welcome") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Welcome)}

type ControlInfo = {
	Control: string,
	Text: string?,
}

local kbmControls: {ControlInfo} = {
	{
		Control = "Crouch",
	},
	{
		Control = "Drop",
		Text = "Drop Item",
	},
	{
		Control = "Drop Ammo",
	},
	{
		Control = "Reload Weapon",
		Text = "Reload",
	},
	{
		Control = "Interact",
	},
	{
		Control = "Flashlight",
	},
	{
		Control = "Equipment",
		Text = "Equipment Menu",
	},
	{
		Control = "Playerlist",
	},
	{
		Control = "Settings",
	},
	{
		Control = "Quick Chat",
	},
	{
		Control = "Team Chat",
	},
	{
		Control = "Team Voice",
	},
	{
		Control = "Sound Player",
	},
}

local gamepadControls: {ControlInfo} = {
	{
		Control = "Crouch",
	},
	{
		Control = "Drop",
		Text = "Drop Item",
	},
	{
		Control = "Reload Weapon",
		Text = "Reload",
	},
	{
		Control = "Interact",
	},
	{
		Control = "Drop Ammo",
	},
	{
		Control = "Menu Picker",
	},
	{
		Control = "Equipment",
		Text = "Equipment Menu",
	},
	{
		Control = "Playerlist",
	},
	{
		Control = "Quick Chat",
	},
	{
		Control = "Team Voice",
	},
	{
		Control = "Next Item",
	},
	{
		Control = "Previous Item",
	},
	{
		Control = "Inventory",
	},
}

local kbmControlInstances: {GuiObject} = {}
local gamepadControlInstances: {GuiObject} = {}

local function createControlInstance(index: number, info: ControlInfo): GuiObject
	local frame = ui.Object.Controls.Frame.Template:Clone()
	frame.Name = info.Control
	frame.TextLabel.Text = info.Text or info.Control
	frame.Visible = false
	frame.LayoutOrder = index

	frame:SetAttribute("Control", info.Control)
	frame:AddTag("ControlHint")

	frame.Parent = ui.Object.Controls.Frame
	return frame
end

for i, info in kbmControls do
	table.insert(kbmControlInstances, createControlInstance(i, info))
end

for i, info in gamepadControls do
	table.insert(gamepadControlInstances, createControlInstance(i, info))
end

ControlManager.PreferredInput:Connect(function(preferred)
	for _, instance in kbmControlInstances do
		instance.Visible = preferred == Enum.PreferredInput.KeyboardAndMouse
	end

	for _, instance in gamepadControlInstances do
		instance.Visible = preferred == Enum.PreferredInput.Gamepad or preferred == Enum.PreferredInput.MicroGamepad
	end
end, true)

ui:ToggleVisible(true)

return nil