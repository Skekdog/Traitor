local UIManager = require(script.Parent.UIManager)

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
		Control = "Equipment Shop",
		Text = "(As Special Role) Shop",
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
}

for i, info in controls do
	local frame = ui.Object.Controls.Template:Clone()
	frame.Name = info.Control
	frame.TextLabel.Text = info.Text or info.Control
	frame.Visible = true
	frame.LayoutOrder = i

	frame:SetAttribute("Control", info.Control)
	frame:AddTag("ControlHint")
	
	frame.Parent = ui.Object.Controls
end

ui:ToggleVisible(true)

return nil