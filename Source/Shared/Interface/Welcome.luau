local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local UIManager = require(script.Parent.UILib.UIManager)

local ui = UIManager.WaitForUI("Welcome") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Welcome)}

type ControlInfo = {
	Control: string,
	Text: string?,
}

local controls: {ControlInfo} = {
	{
		Control = "Crouch",
		Text = "Crouch & Covert Search",
	},
	{
		Control = "Equipment",
		Text = "Equipment Menu",
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
		Control = "Playerlist",
	},
	{
		Control = "Settings",
	},
	{
		Control = "Next Item",
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
}

local controlInstances: {GuiObject} = {}

for i, info in controls do
	local frame = ui.Object.Controls.Frame.Template:Clone()
	frame.Name = info.Control
	frame.TextLabel.Text = info.Text or info.Control
	frame.Visible = true
	frame.LayoutOrder = i

	frame:SetAttribute("Control", info.Control)
	frame:AddTag("ControlHint")

	frame.Parent = ui.Object.Controls.Frame

	table.insert(controlInstances, frame)
end

ControlManager.PreferredInput:Connect(function(preferred)
	for _, instance in controlInstances do
		instance.Visible = preferred ~= Enum.PreferredInput.Touch
	end
end, true)

ui:ToggleVisible(true)

return nil