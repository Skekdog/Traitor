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

local UIRegistered = Instance.new("BindableEvent", script)
function UIManager.RegisterUI(object: GuiObject): UI
	local name = object.Name
	local layer: Layer = object:GetAttribute("Layer")
	local displayName: string? = object:GetAttribute("DisplayName")
	local sidebar: boolean? = object:GetAttribute("Sidebar")
	local preventClose: boolean? = object:GetAttribute("PreventClose")
	local ignoreInset: boolean? = object:GetAttribute("IgnoreInset")
	local modal: boolean? = object:GetAttribute("Modal")

	local transitionStyle: "Position" | "Size" = object:GetAttribute("TransitionStyle")
	local transitionTarget: UDim2 = object:GetAttribute("TransitionTarget")
	local self: UI = {
		Name = name,
		Layer = layer,
		DisplayName = displayName or name,
		Visible = object.Visible,
		NoClose = preventClose,
		Sidebar = sidebar,
		Object = object,

		ToggleVisible = function(self: UI, force: boolean?, ignoreOtherUIs: boolean?)
			
		end,

		Unregister = function(self: UI)
			ControlManager.Unregister(name)
			self:ToggleVisible(false, true)
			self.Object.Parent = script.UnregisteredUIs
			
			if self.Sidebar then
				local sb = UIManager.GetUI("Sidebar").Object; -- Ambiguous syntax means we need a semicolon here, day ruined
				(sb :: any)[name]:Destroy()
			end
			
			table.remove(registeredUIs, table.find(registeredUIs, self))
		end
	}
	
	if layer == "Popup" and not object:GetAttribute("NoKeybind") then
		ControlManager.Register(name, false, function(act, state, input, toggled)
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
		local sb = UIManager.GetUI("Sidebar").Object :: typeof(script.UnregisteredUIs.Sidebar)
		if not ReplicatedFirst:GetAttribute("ControlsReady") then
			ReplicatedFirst:GetAttributeChangedSignal("ControlsReady"):Wait()
		end
		local but = sb.Button:Clone()
		local keybinding = requestSetting:Invoke(name)
		local key = keybinding["Keycodes"][1][1]
		local modifier = keybinding["Keycodes"][1][2]
		local str = ""
		if key then
			str = ControlManager.getStringForKeyCode(key)
			if modifier then
				str = " + "..ControlManager.getStringForKeyCode(modifier)
			end
		end
		but.Name = name
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
		elseif layer == "Popup" then
			warn(name.." does not have a registered Close button!")
		end
	end
	
	if ignoreInset and not object:GetAttribute("InsetAdjusted") then
		object:SetAttribute("InsetAdjusted", true)
		object.Position -= UDim2.fromOffset(inset.X, inset.Y)
		object.Size += UDim2.fromOffset(inset.X, inset.Y)
	end
	
	if transitionStyle then
		if not transitionTarget then -- check to make sure transTarget is not already set, because uis like EquipmentShop are registered multiple times
			object:SetAttribute("TransitionTarget", transitionStyle == "Size" and object.Size or object.Position)
		end
	elseif layer == "Popup" then
		warn(name.." does not have a transition style!")
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
	
	object.Parent = plrUi:FindFirstChild(layer)
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
function UIManager.UpdateThemeInstance(v: Instance, theme): ()
	-- Updates the theme for one instance
	-- Tag StyledUI means that a UI object will be updated to match the theme
	-- Attribute Style is the style to use for the main element(s) of an object (e.g, background colour for a frame, image colour for an image)
	
	local tweenInfo = TweenInfo.new(requestSetting:Invoke("Animate UI Transitions") and THEME_TRANSITION_TIME or 0, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
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

function UIManager.UpdateTheme(themeName: string): nil
	local theme = UIManager.Themes[themeName]
	if not theme then return error("Theme "..tostring(themeName).." not found!") end

	for _, v in game:GetService("CollectionService"):GetTagged("StyledUI") do
		UIManager.UpdateThemeInstance(v, theme)
	end
	return
end

function UIManager:ToggleVisible(force: boolean?, ignoreOtherUIs: boolean?): nil --Shows/hides a UI
	if force == true then
		if self.Visible then
			return
		end
		self.Visible = true
	elseif force == false then
		if not self.Visible then
			return
		end
		self.Visible = false
	elseif not force then
		self.Visible = not self.Visible
	end
	
	local frame: Frame = self.UI
	
	if frame:GetAttribute("TransitionStyle") then
		API.TransitionUIState(frame, self.Visible)
	else
		frame.Visible = self.Visible
	end
	
	local scrUI: ScreenGui = (plrUi :: any)[self.UIType]
	
	if ignoreOtherUIs or (scrUI:GetAttribute("IgnoreStacking")) then
		return
	end
	
	local bgMenuMode = script:GetAttribute("BackgroundMenuMode")

	if self.Visible then
		local highestIndex = 1
		for _, v in UIManager.GetUIs(self.UIType) do
			if v.Visible and (v.Object.ZIndex > highestIndex) then
				highestIndex = v.Object.ZIndex
			end
		end
		frame.ZIndex = highestIndex + 1
	else
		frame.ZIndex = 1
	end
	
	if bgMenuMode ~= "Stacked" then
		if bgMenuMode == "Closed" then
			for _, v in scrUI:GetChildren() do
				if v ~= frame then
					UIManager.GetUI(v.Name):ToggleVisible(false, true)
				end
			end
			return
		end
		
		-- Now bgMenuMode == "Hidden"
		if self.Visible then
			for _, v in UIManager.GetUIs(self.UIType) :: any  do
				if v.Visible and (v ~= self) then
					scrUI:SetAttribute("NextUI", v.Name..";"..scrUI:GetAttribute("NextUI"))
					v:ToggleVisible(false, true)
				end
			end
		else
			local nextUI = scrUI:GetAttribute("NextUI"):split(";")
			if not nextUI[1] or nextUI[1] == "" then
				return
			end
			local ui = UIManager.GetUI(nextUI[1])
			if not ui then
				return
			end
			ui:ToggleVisible(true, true)
			scrUI:SetAttribute("NextUI", table.concat(nextUI, ";", 2, #nextUI))
		end
	end
	return
end

return UIManager