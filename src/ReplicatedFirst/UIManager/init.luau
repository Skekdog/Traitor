local plr = game:GetService("Players").LocalPlayer
local plrUi = plr.PlayerGui

local ControlManager = require(game:GetService("ReplicatedFirst").ControlManager)

local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local inset = game:GetService("GuiService"):GetGuiInset()
while inset == Vector2.zero do
	inset =  game:GetService("GuiService"):GetGuiInset()
	task.wait()
end

local API = require(script.Parent.API)

local uis = {
	HUD = plrUi:WaitForChild("HUD", math.huge), --Lowest priority (RoundInfo) Always displayed below everything else
	Popup = plrUi:WaitForChild("Popup", math.huge), --Low priority (ScreenMessage) Displayed above HUD
	UserTriggered = plrUi:WaitForChild("UserTriggered", math.huge), --High priority (EquipmentShop, PlayerList) Displayed above nearly everything else
	Buttons = plrUi:WaitForChild("Buttons", math.huge), --On-Screen buttons. Highest priority (Sidebar, Inventory, ContextActionService) Displayed above everything else
	Special = plrUi:WaitForChild("Special", math.huge) -- The highest priority. Intended for special cases like ScreenMessage.
}

local requestSetting = script.Parent.SettingsManager.RequestSetting

local UIManager = {}
UIManager.__index = UIManager

export type UIType = "HUD"|"Popup"|"UserTriggered"|"Buttons"

export type UI = typeof(setmetatable({}, {})) & {
	ToggleVisible:(self: UI, force: boolean?, ignoreOtherUIs: boolean?) -> nil,
	Name: string, --An identifier of the UI. Must be unique in a UIType.
	DisplayName: string, -- Name showed in sidebar
	Visible: boolean, --Self-explanatory.
	PreventClose: boolean, --Prevents the UI from being closed with the X key.
	UIType: UIType, --UIType
	UI: GuiObject, --A reference to the frame object.
}

local registeredUIs: {UI} = {}

local UIRegistered = (script:FindFirstChild("Event") :: BindableEvent) or Instance.new("BindableEvent", script)
function UIManager.RegisterUI<T>(name: string, uiType: UIType, ignoreInset: boolean, ui: Frame, displayName: string?, preventClose: boolean): UI & {UI: T}
	local self: UI = {} :: UI
	
	self.Name = name
	self.DisplayName = displayName or name
	self.Visible = ui.Visible
	self.PreventClose = preventClose
	self.UIType = uiType
	self.UI = ui
	
	if (uiType == "UserTriggered") and (not ui:GetAttribute("NoKeybind")) then
		task.delay(0, function() -- We delay to avoid initialisation never happening. Kludge. But it works.
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
		end)
	end
	
	if ui:GetAttribute("Sidebar") then
		local sb: typeof(script.UnregisteredUIs.Buttons.Sidebar) = UIManager.GetUI("Sidebar").UI
		local function add()
			if not game:GetService("ReplicatedFirst"):GetAttribute("ControlsReady") then
				game:GetService("ReplicatedFirst"):GetAttributeChangedSignal("ControlsReady"):Wait()
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
			but.MouseButton1Click:Connect(function() self:ToggleVisible() end)
		end
		task.delay(0.1, add) -- 1 second delay because it doesn't work otherwise. Don't ask me why.
	end
	
	if not ui:GetAttribute("NoClose") then
		local close = ui:FindFirstChild("CloseUI") :: ObjectValue & {Value: TextButton}
		if close then
			close.Value.MouseButton1Click:Connect(function()
				self:ToggleVisible(false)
			end)
		elseif uiType == "UserTriggered" then
			warn(name.." does not have a registered Close button!")
		end
	end
	
	if ignoreInset then
		ui.Position -= UDim2.fromOffset(inset.X, inset.Y)
		ui.Size += UDim2.fromOffset(inset.X, inset.Y)
	end
	
	local transitionStyle = ui:GetAttribute("TransitionStyle")
	if transitionStyle then
		if not ui:GetAttribute("TransitionTarget") then -- check to make sure transTarget is not already set, because uis like EquipmentShop are registered multiple times
			ui:SetAttribute("TransitionTarget", transitionStyle == "Size" and ui.Size or ui.Position)
		end
	elseif ((self.UIType == "Popup") or (self.UIType == "UserTriggered")) and not ui:GetAttribute("NoTransition") then
		warn(ui.Name.." does not have a transition style!")
	end
	
	-- Disabled when ui is closing but not fully closed yet
	if ui:GetAttribute("Modal") then
		local modalise = Instance.new("TextButton")
		modalise.Modal = true
		modalise.Size = UDim2.new()
		modalise.Name = "Modalise"
		modalise.BackgroundTransparency = 1
		modalise.TextTransparency = 1
		
		modalise.Visible = true
		
		modalise.Parent = ui
	end
	
	ui.Parent = uis[uiType]
	self = setmetatable(self, UIManager)
	table.insert(registeredUIs, self)
	UIRegistered:Fire(self.Name)
	return self :: any
end

function UIManager.UnregisterUI(name: string, uiType: UIType): nil
	local reg
	for i, v in registeredUIs do
		if (v.UIType == (uiType or v.UIType)) and (v.Name == name) then -- que?
			reg = v
			table.remove(registeredUIs, i)
			break
		end
	end
	
	if reg then
		ControlManager.Unregister(name)
		
		if reg.UI:GetAttribute("Sidebar") then
			pcall(function()
				reg.UI.Visible = false
				reg.UI.Parent = (script :: any).UnregisteredUIs[uiType]
				local sb: typeof(script.UnregisteredUIs.Buttons.Sidebar) = UIManager.GetUI("Sidebar").UI
				sb:FindFirstChild(name):Destroy()
			end)
		end
	end
	return
end

function UIManager.TryGetUI(name: string): UI?
	for _, v in registeredUIs do
		if v.Name == name then
			return v
		end
	end
	return
end

function UIManager.GetUI<T>(name: string): UI & {UI: T}
	for _, v in registeredUIs do
		if v.Name == name then
			return v :: any
		end
	end
	error("Failed to find UI: "..name)
end

function UIManager.GetUIs(uiType: UIType): {UI}
	local uis = {}
	for _, v in registeredUIs do
		if v.UIType == uiType then
			table.insert(uis, v)
		end
	end
	return uis
end

function UIManager.WaitForUI<T>(name: string, ignoreYield: boolean?): UI & {UI: T}
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
	return UIManager.TryGetUI(name) :: any
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
	
	local scrUI: ScreenGui = uis[self.UIType]
	
	if ignoreOtherUIs or (scrUI:GetAttribute("IgnoreStacking")) then
		return
	end
	
	local bgMenuMode = script:GetAttribute("BackgroundMenuMode")

	if self.Visible then
		local highestIndex = 1
		for _, v in UIManager.GetUIs(self.UIType) do
			if v.Visible and (v.UI.ZIndex > highestIndex) then
				highestIndex = v.UI.ZIndex
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