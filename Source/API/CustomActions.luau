local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local CustomActions = {}

local actions: {[number]: string} = {}
local callbacks: {[string]: () -> ()?} = {}

local ui = (UIManager.WaitForUI("LeftArea") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.LeftArea)}).Object

function CustomActions.Register(name: string, callback: () -> (), preferredSlot: number?, displayName: string?): ()
	assert(preferredSlot == nil or preferredSlot > 0 and preferredSlot < 4, "preferredSlot must be between 1 and 3, or nil")

	for _, action in actions do
		if action == name then
			return
		end
	end

	local slot = if not preferredSlot or actions[preferredSlot] then #actions + 1 else preferredSlot
	actions[slot] = name

	local button = ui.Actions.ButtonTemplate:Clone()
	button.TextLabel.Text = if displayName then displayName else name
	button.LayoutOrder = slot
	button.Name = tostring(slot)
	button:SetAttribute("Control", "Action " .. slot)
	button:AddTag("ControlHint")
	button.Visible = true
	button.Parent = ui.Actions

	callbacks[name] = callback

	button.Activated:Connect(function()
		callback()
	end)

	ControlManager.Register("Action " .. slot, function()
		callback()
		return Enum.ContextActionResult.Pass
	end)
end

function CustomActions.Unregister(name: string): ()
	for index, action in actions do
		if action == name then
			actions[index] = nil
			ControlManager.Unregister("Action " .. index)
			callbacks[name] = nil

			local button = ui.Actions:FindFirstChild(tostring(index))
			if button then
				button:Destroy()
			end

			break
		end
	end
end

function CustomActions.Trigger(name: string): ()
	local callback = callbacks[name] or error("Action " .. name .. " not found")
	callback()
end

return table.freeze(CustomActions)