local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local ToggleMouseVisible = require(ReplicatedStorage.Shared.Interface.Util.ToggleMouseVisible)
local SettingDefinitions = require(ReplicatedStorage.Shared.Settings.SettingDefinitions)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)
local UIAnimation = require(script.Parent.UIAnimation)

local plr = Players.LocalPlayer
local plrUi = plr.PlayerGui

local inset: Vector2
do
	local insetGui = Instance.new("ScreenGui")
	insetGui.ScreenInsets = Enum.ScreenInsets.None
	insetGui.Parent = StarterGui

	repeat
		inset = -insetGui.AbsolutePosition
		task.wait()
	until inset.Y > 0 or GuiService:IsTenFootInterface() -- vertical inset doesn't load immediately. on consoles, there is no vertical inset.
end

--[[ Principles:
- Special is the highest layer
- Popups are 2nd highest. All popups should appear on top of others when they are made visible
- Buttons 3rd
- HUD is lowest layer

- All popups must have a close button and transition style
]]

local UIManager = {}

export type Layer = "Special" | "Popup" | "Buttons" | "HUD" | "ActionButtons"

export type UI = {
	Name: string, -- Unique identifier
	Layer: Layer,
	KeepCursorVisible: boolean?,
	DisplayName: string, -- Name shown in sidebar
	NoClose: boolean?, -- Prevents closing with the X key
	Visible: boolean,
	Sidebar: boolean?,
	Object: GuiObject,
	NoCursor: boolean?,

	ToggleVisible: (self: UI, force: boolean?, ignoreOtherUIs: boolean?, callback: (() -> ())?) -> (),
	Unregister: (self: UI) -> (),
}

local registeredUIs: {UI} = {}

UIManager.UnregisteredUIs = ReplicatedStorage.Assets.UnregisteredUIs
UIManager.GuiInset = inset

local function tryMakeCursorVisible(): ()
	for _, v in registeredUIs do
		if v.Visible and (v.Layer == "Popup" or v.KeepCursorVisible) and not v.NoCursor then
			return ToggleMouseVisible(true)
		end
	end

	ToggleMouseVisible(false)
end

UIManager.RegisteredEvent = DynamicValue.new("")

function UIManager.RegisterUI<T>(object: GuiObject & T): UI & {Object: T}
	local ignoreInset = object:GetAttribute("IgnoreInset") :: boolean?
	local accountForInset = object:GetAttribute("AccountForInset") :: boolean | "X" | "Y" | "XY"?
	local modal = object:GetAttribute("Modal") :: boolean?
	local transitionStyle = object:GetAttribute("TransitionStyle") :: "Position" | "Size" | "Transparency"
	local transitionTarget = object:GetAttribute("TransitionTarget") :: UDim2

	local layer = object:GetAttribute("Layer")
	assert(layer == "Special" or layer == "Popup" or layer == "Buttons" or layer == "HUD" or layer == "ActionButtons")

	local self: UI = {
		Name = object.Name,
		Layer = layer,
		DisplayName = object:GetAttribute("DisplayName") :: string? or object.Name,
		Visible = object.Visible,
		NoClose = object:GetAttribute("PreventClose") :: boolean?,
		Sidebar = object:GetAttribute("Sidebar") :: boolean?,
		Object = object,
		NoCursor = object:GetAttribute("NoCursor") :: boolean?,

		KeepCursorVisible = object:GetAttribute("KeepCursorVisible") :: boolean?,

		ToggleVisible = function(self: UI, force: boolean?, ignoreOtherUIs: boolean?, callback: ((Enum.PlaybackState) -> ())?)
			local newVisible = if force ~= nil then force else not self.Visible

			if newVisible == self.Visible then
				if callback then
					callback(Enum.PlaybackState.Cancelled)
				end
				return
			end

			self.Visible = newVisible

			tryMakeCursorVisible()

			local object = self.Object
			if transitionStyle then
				local tween = UIAnimation.TransitionUIState(object, newVisible)
				if callback then
					if tween then
						tween.Completed:Once(callback)
					else
						callback(Enum.PlaybackState.Completed)
					end
				end
			else
				object.Visible = newVisible
				if callback then
					callback(Enum.PlaybackState.Completed)
				end
			end

			if ignoreOtherUIs or self.Layer ~= "Popup" or self.Object:GetAttribute("IgnoreStacking") then
				return
			end

			if not newVisible then
				object.ZIndex = 0
				return
			end

			local highestIndex = 0
			for _, ui in registeredUIs do
				if ui.Layer == "Popup" and highestIndex < ui.Object.ZIndex and ui.Visible then
					highestIndex = ui.Object.ZIndex
				end
			end

			object.ZIndex = highestIndex + 1
		end,

		Unregister = function(self: UI)
			if not table.find(registeredUIs, self) then
				return warn(self.Name.." is not registered!")
			end
			ControlManager.Unregister(self.Name)
			self:ToggleVisible(false, true, function()
				object.Parent = UIManager.UnregisteredUIs
			end)

			if self.Sidebar then
				local sb = UIManager.GetUI("Sidebar").Object
				local sbButton = sb:FindFirstChild(self.Name)
				if sbButton then
					sbButton:Destroy()
				end
			end

			table.remove(registeredUIs, table.find(registeredUIs, self))
		end
	}

	if (self.Layer == "Popup" and not object:GetAttribute("NoKeybind")) or object:GetAttribute("HasKeybind") then
		ControlManager.Register(self.Name, function(act, state, input)
			local isToggled = (Settings.GetSetting(self.Name) :: SettingDefinitions.ControlValue).Toggled

			if isToggled then
				if state == Enum.UserInputState.End then
					self:ToggleVisible()
				end
			else
				if state == Enum.UserInputState.Begin then
					self:ToggleVisible(true)
				elseif state == Enum.UserInputState.End then
					self:ToggleVisible(false)
				end
			end

			return Enum.ContextActionResult.Pass
		end)
	end

	if self.Sidebar then
		local sb = UIManager.GetUI("Sidebar").Object :: typeof(UIManager.UnregisteredUIs.Sidebar)

		local entry = sb.Entry:Clone()
		entry.Name = self.Name

		entry.Button.Text = self.DisplayName

		entry:SetAttribute("Control", self.Name)
        entry:SetAttribute("NoStyle", true)
        entry:SetAttribute("Size", UDim2.fromScale(0, 0.5))
		entry:SetAttribute("HideNone", true)
		entry:SetAttribute("TextXAlignment", "Right")
        entry:AddTag("ControlHint")

		entry.ZIndex = -#sb:GetChildren()

		entry.Visible = true
		entry.Parent = sb

		entry.Button.Activated:Connect(function()
			self:ToggleVisible()
		end)
	end

	if not self.NoClose then
		local close = object:FindFirstChild("CloseUI") :: (ObjectValue & {Value: TextButton})?
		if close and close.Value then
			close.Value.MouseButton1Click:Connect(function()
				self:ToggleVisible(false)
			end)
		elseif self.Layer == "Popup" then
			warn(self.Name.." does not have a registered Close button!")
		end
	end

	if accountForInset and not object:GetAttribute("InsetAdjusted") then
		object:SetAttribute("InsetAdjusted", true)

		local thisInset: UDim2
		if accountForInset == true or accountForInset == "XY" then
			thisInset = UDim2.fromOffset(inset.X, inset.Y)
		elseif accountForInset == "X" then
			thisInset = UDim2.fromOffset(inset.X, 0)
		elseif accountForInset == "-X" then
			thisInset = UDim2.fromOffset(-inset.X, 0)
		elseif accountForInset == "Y" then
			thisInset = UDim2.fromOffset(0, inset.Y)
		else
			error("Unexpected type for 'AccountForInset' attribute: " .. object:GetFullName())
		end

		object.Position += thisInset
	end

	if ignoreInset and not object:GetAttribute("InsetAdjusted") then
		object:SetAttribute("InsetAdjusted", true)
		object.Size += UDim2.fromOffset(inset.X, inset.Y)
	end

	if transitionStyle then
		if not transitionTarget then -- check to make sure transTarget is not already set, because uis like EquipmentShop are registered multiple times
			local target: UDim2 | number
			if transitionStyle == "Size" then
				target = object.Size
			elseif transitionStyle == "Position" then
				target = object.Position
			elseif transitionStyle == "Transparency" then
				target = object.BackgroundTransparency
			end
			object:SetAttribute("TransitionTarget", target)
		end
	elseif self.Layer == "Popup" then
		warn(self.Name.." does not have a transition style!")
	end

	-- Disabled when ui is closing but not fully closed yet
	if modal and not object:FindFirstChild("Modalise") then
		local modalise = Instance.new("TextButton")
		modalise.Modal = true
		modalise.Size = UDim2.new()
		modalise.Name = "Modalise"
		modalise.BackgroundTransparency = 1
		modalise.TextTransparency = 1
		modalise.Size = UDim2.fromOffset(1, 1)

		modalise.Visible = true

		modalise.Parent = object
	end

	object.Parent = plrUi:FindFirstChild(self.Layer)
	table.insert(registeredUIs, self)

	UIManager.RegisteredEvent:SetValue(self.Name)

	return self :: UI & {Object: T}
end

function UIManager.TryGetUI(name: string): UI?
	for _, v in registeredUIs do
		if v.Name == name then
			return v
		end
	end
	return
end

function UIManager.GetUI(name: string): UI
	for _, v in registeredUIs do
		if v.Name == name then
			return v
		end
	end
	error("Failed to find UI: "..name)
end

function UIManager.GetUIs(layer: Layer): {UI}
	local uis = {}
	for _, v in registeredUIs do
		if v.Layer == layer then
			table.insert(uis, v)
		end
	end
	return uis
end

function UIManager.WaitForUI(name: string, ignoreYield: boolean?): UI
	local start = os.clock()
	local warned = false
	repeat
		task.wait()
		if not warned and not ignoreYield then
			if start + 5 <= os.clock() then
				warned = true
				warn(debug.traceback(`Infinite yield possible on WaitForUI("{name}")`, 0))
			end
		end
	until UIManager.TryGetUI(name)
	return UIManager.GetUI(name)
end

local orders: {[Layer]: number} = {
	ActionButtons = 5,
	Special = 4,
	Popup = 3,
	Buttons = 2,
	HUD = 1,
}

for layer: Layer, order in orders do
	local screenUi = Instance.new("ScreenGui")
	screenUi.Name = layer
	screenUi.IgnoreGuiInset = true
	screenUi.DisplayOrder = order
	screenUi.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenUi.ClipToDeviceSafeArea = false
	screenUi.ResetOnSpawn = false
	screenUi.ScreenInsets = if layer == "ActionButtons" then Enum.ScreenInsets.DeviceSafeInsets else Enum.ScreenInsets.None

	if layer == "Buttons" then
		screenUi.ScreenInsets = Enum.ScreenInsets.None
	end

	screenUi.Parent = Players.LocalPlayer.PlayerGui
end

UIManager.RegisterUI(UIManager.UnregisteredUIs.Sidebar)

local function register(object: Instance)
	if object:GetAttribute("DoNotRegister") then
		return
	end

	UIManager.RegisterUI(object :: GuiObject)
end

UIManager.UnregisteredUIs.ChildAdded:Connect(register)
for _, object in UIManager.UnregisteredUIs:GetChildren() do
	register(object)
end

ControlManager.Register("Close UI", function()
	for _, v in UIManager.GetUIs("Popup") do
		if v.Visible and not v.NoClose then
			v:ToggleVisible(false)
			return Enum.ContextActionResult.Pass
		end
	end
	return Enum.ContextActionResult.Pass
end)

return table.freeze(UIManager)