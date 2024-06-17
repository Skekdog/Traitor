local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local ControlManager = require(ReplicatedFirst.ControlManager)
local API = require(script.Parent.API)

local plr = Players.LocalPlayer
local plrUi = plr.PlayerGui

-- Undocumented behaviour, but GetGuiInset() returns zero sometimes
local inset = GuiService:GetGuiInset()
while inset == Vector2.zero do
	inset =  GuiService:GetGuiInset()
	task.wait()
end

--[[ Principles:
- Special is the highest layer
- Popups are 2nd highest. All popups should appear on top of others when they are made visible
- Buttons 3rd
- HUD is lowest layer

- All popups must have a close button and transition style
]]

local requestSetting = script.Parent.SettingsManager.RequestSetting

local UIManager = {}

export type Layer = "Special" |"Popup" | "Button" | "HUD"
export type BackgroundMenuMode = "Closed" | "Hidden" | "Stacked"

export type UI = {
	Name: string, -- Unique identifier
	Layer: Layer,
	DisplayName: string, -- Name shown in sidebar
	NoClose: boolean?, -- Prevents closing with the X key
	Visible: boolean,
	Sidebar: boolean?,
	Object: GuiObject,

	ToggleVisible: (self: UI, force: boolean?, ignoreOtherUIs: boolean?) -> (),
	Unregister: (self: UI) -> (),
}

local registeredUIs: {UI} = {}
local nextUI: UI

UIManager.UnregisteredUIs = script.UnregisteredUIs

local UIRegistered = Instance.new("BindableEvent", script)
function UIManager.RegisterUI(object: GuiObject): UI
	local ignoreInset: boolean? = object:GetAttribute("IgnoreInset")
	local modal: boolean? = object:GetAttribute("Modal")
	local transitionStyle: "Position" | "Size" = object:GetAttribute("TransitionStyle")
	local transitionTarget: UDim2 = object:GetAttribute("TransitionTarget")

	local self: UI = {
		Name = object.Name,
		Layer = object:GetAttribute("Layer"),
		DisplayName = object:GetAttribute("DisplayName") or object.Name,
		Visible = object.Visible,
		NoClose = object:GetAttribute("PreventClose"),
		Sidebar = object:GetAttribute("Sidebar"),
		Object = object,

		ToggleVisible = function(self: UI, force: boolean?, ignoreOtherUIs: boolean?)
			local newVisible = if force ~= nil then force else not self.Visible
			self.Visible = newVisible

			local object = self.Object
			if transitionStyle then
				API.TransitionUIState(object, newVisible)
			else
				object.Visible = newVisible
			end

			if ignoreOtherUIs or self.Layer ~= "Popup" or self.Object:GetAttribute("IgnoreStacking") then
				return
			end

			if not newVisible then
				object.ZIndex = 0
				return
			end

			local mode: BackgroundMenuMode = script:GetAttribute("BackgroundMenuMode")
			local highestIndex = 0
			for _, ui in registeredUIs do
				if ui.Layer == "Popup" and highestIndex < ui.Object.ZIndex and ui.Visible then
					highestIndex = ui.Object.ZIndex
					if ui ~= self and mode == "Closed" and not ui.Object:GetAttribute("IgnoreStacking") then
						ui:ToggleVisible(false, true)
					end
				end
			end
			object.ZIndex = highestIndex + 1

			if mode == "Hidden" then
				if nextUI and nextUI ~= self then
					nextUI:ToggleVisible(false, true)
				end

				nextUI = self
			end
		end,

		Unregister = function(self: UI)
			ControlManager.Unregister(self.Name)
			self:ToggleVisible(false, true)
			self.Object.Parent = UIManager.UnregisteredUIs
			
			if self.Sidebar then
				local sb = UIManager.GetUI("Sidebar").Object; -- Ambiguous syntax means we need a semicolon here, day ruined
				(sb :: any)[self.Name]:Destroy()
			end
			
			table.remove(registeredUIs, table.find(registeredUIs, self))
		end
	}
	
	if self.Layer == "Popup" and not object:GetAttribute("NoKeybind") then
		ControlManager.Register(self.Name, false, function(act, state, input, toggled)
			if not toggled then
				if state == Enum.UserInputState.End then
					self:ToggleVisible(false)
				elseif state == Enum.UserInputState.Begin then
					self:ToggleVisible(true)
				end
				return
			end
			self:ToggleVisible()
		end)
	end
	
	if self.Sidebar then
		local sb = UIManager.GetUI("Sidebar").Object :: typeof(UIManager.UnregisteredUIs.Sidebar)
		if not ReplicatedFirst:GetAttribute("ControlsReady") then
			ReplicatedFirst:GetAttributeChangedSignal("ControlsReady"):Wait()
		end
		local but = sb.Button:Clone()
		local keybinding = requestSetting:Invoke(self.Name)
		local key = keybinding["Keycodes"][1][1]
		local modifier = keybinding["Keycodes"][1][2]
		local str = ""
		if key then
			str = ControlManager.GetStringForKeyCode(key)
			if modifier then
				str = " + "..ControlManager.GetStringForKeyCode(modifier)
			end
		end
		but.Name = self.Name
		but.Text = self.DisplayName..(UIS.KeyboardEnabled and "<br/>["..str.."]" or "")
		but.Visible = true
		but.Parent = sb
		but.MouseButton1Click:Connect(function()
			self:ToggleVisible()
		end)
	end
	
	if not self.NoClose then
		local close = object:FindFirstChild("CloseUI") :: (ObjectValue & {Value: TextButton})?
		if close then
			close.Value.MouseButton1Click:Connect(function()
				self:ToggleVisible(false)
			end)
		elseif self.Layer == "Popup" then
			warn(self.Name.." does not have a registered Close button!")
		end
	end
	
	if ignoreInset and not object:GetAttribute("InsetAdjusted") then
		object:SetAttribute("InsetAdjusted", true)
		object.Size += UDim2.fromOffset(inset.X, inset.Y)
	end
	
	if transitionStyle then
		if not transitionTarget then -- check to make sure transTarget is not already set, because uis like EquipmentShop are registered multiple times
			object:SetAttribute("TransitionTarget", transitionStyle == "Size" and object.Size or object.Position)
		end
	elseif self.Layer == "Popup" then
		warn(self.Name.." does not have a transition style!")
	end
	
	-- Disabled when ui is closing but not fully closed yet
	if modal then
		local modalise = Instance.new("TextButton")
		modalise.Modal = true
		modalise.Size = UDim2.new()
		modalise.Name = "Modalise"
		modalise.BackgroundTransparency = 1
		modalise.TextTransparency = 1
		
		modalise.Visible = true
		
		modalise.Parent = object
	end
	
	object.Parent = plrUi:FindFirstChild(self.Layer)
	table.insert(registeredUIs, self)
	UIRegistered:Fire(self.Name)
	return self
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
	local start = os.time()
	local warned = false
	repeat
		task.wait()
		if not warned and not ignoreYield then
			if start+5 <= os.time() then
				warned = true
				warn("Infinite yield possible on WaitForUI("..name..")\n"..debug.traceback())
			end
		end
	until UIManager.TryGetUI(name)
	return UIManager.GetUI(name)
end

UIManager.Themes = {
	Light = {
		Primary = Color3.fromRGB(250, 250, 250),
		Secondary = Color3.fromRGB(235, 235, 235),
		Text = Color3.fromRGB(0, 0, 0),
		TextStroke = Color3.fromRGB(255, 255, 255),
		UIStroke = Color3.fromRGB(0, 0, 0),
	},
	Dark = {
		Primary = Color3.fromRGB(17, 17, 17),
		Secondary = Color3.fromRGB(34, 34, 34),
		Text = Color3.fromRGB(255, 255, 255),
		TextStroke = Color3.fromRGB(0, 0, 0),
		UIStroke = Color3.fromRGB(255, 255, 255),
	},
	Blue = {
		Primary = Color3.fromRGB(33, 66, 200),
		Secondary = Color3.fromRGB(67, 123, 255),
		Text = Color3.fromRGB(255, 255, 255),
		TextStroke = Color3.fromRGB(0, 0, 0),
		UIStroke = Color3.fromRGB(255, 255, 255),
	},
}

local THEME_TRANSITION_TIME = 0.25
function UIManager.UpdateThemeInstance(v: Instance, theme, noTransition: boolean?): ()
	-- Updates the theme for one instance
	-- Tag StyledUI means that a UI object will be updated to match the theme
	-- Attribute Style is the style to use for the main element(s) of an object (e.g, background colour for a frame, image colour for an image)
	
	local tweenInfo = TweenInfo.new((requestSetting:Invoke("Animate UI Transitions") and not noTransition) and THEME_TRANSITION_TIME or 0, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
	theme = theme or UIManager.Themes.Dark
	
	local styleData = (v:GetAttribute("StyleData") or ""):split(";")
	local inverse = table.find(styleData, "Inverse")
	local keepText = table.find(styleData, "KeepText")
	local updateImage = table.find(styleData, "UpdateImage")
	
	local style = v:GetAttribute("Style")
	
	if v.ClassName == "UIStroke" then
		TS:Create(v, tweenInfo, {Color = theme["UIStroke"]}):Play()
	elseif (v.ClassName == "TextButton") or (v.ClassName == "TextLabel") then
		if not keepText then
			TS:Create(v, tweenInfo, {
				TextColor3 = (not inverse) and theme.Text or theme[style or "Primary"],
				TextStrokeColor3 = (not inverse) and theme.TextStroke or theme[style or "Text"]
			}):Play()
		end
	elseif (v.ClassName == "ImageButton") or (v.ClassName == "ImageLabel") then
		if updateImage then
			TS:Create(v, tweenInfo, {ImageColor3 = (not inverse) and theme[style or "Text"] or theme[style or "Primary"]}):Play()
		end
	end
	
	if v.ClassName ~= "UIStroke" then
		TS:Create(v, tweenInfo, {
			BackgroundColor3 = (not inverse) and theme[style or "Primary"] or theme.Text,
			BorderColor3 = (not inverse) and theme.UIStroke or theme[style or "Primary"]
		}):Play()
	end
	
	if v:GetAttribute("DefaultTextColour") then
		v:SetAttribute("DefaultTextColour", theme.Text)
	end
	
	return
end

function UIManager.UpdateTheme(themeName: string): ()
	local theme = UIManager.Themes[themeName]
	if not theme then
		error("Theme "..tostring(themeName).." not found!")
	end

	for _, v in game:GetService("CollectionService"):GetTagged("StyledUI") do
		UIManager.UpdateThemeInstance(v, theme)
	end
end

return UIManager