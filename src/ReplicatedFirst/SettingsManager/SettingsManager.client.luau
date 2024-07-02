local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local GUI = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SM = require(script.Parent)

-- This must be run before anything yields, especially todo with ui
local options = (ReplicatedStorage:WaitForChild("ServerClient") :: typeof(ReplicatedStorage.ServerClient)).LoadSavedData.OnClientEvent:Wait()
options = SM.JSONDecode(options)
for i, v in options do
	local definition = SM.Settings[i].Definition
	if definition.SpecifyToggle == false then
		v.Toggled = (definition.Default :: SM.KeybindSetting).Toggled
	end
	SM.SetSetting(i, v)
end

ReplicatedFirst:SetAttribute("ControlsReady", true)

local API = require(ReplicatedFirst.API)
local UIManager = require(ReplicatedFirst.UIManager)
local Controls = require(ReplicatedFirst.ControlManager)

local pageBase = script.__TabPage
local tabBase = script.__Tab

local keybindFrame = script.__SettingKeybind
local selectorFrame = script.__SettingSelector
local booleanFrame = script.__SettingBoolean
local touchFrame = script.__SettingTouch
local settingsFrame = (UIManager.WaitForUI("Settings").Object :: typeof(UIManager.UnregisteredUIs.Settings)).Main

local tabsFrame = settingsFrame.Tabs
local tabUnderline = tabsFrame.Underline
local createdTabs = {}
for _, v in SM.AvailableSettings do
	if not table.find(createdTabs, v.Tab) then
		table.insert(createdTabs, v.Tab)
	end
end

local UNDERLINE_TRANSITION_SCALE = 0.125
local function transitionUnderline(underline: Frame, target: TextButton)
	local shouldAnimate = SM.GetSetting("Animate UI Transitions")
	local UNDERLINE_TRANSITION_TIME = SM.GetSetting("Animate UI Transitions") and 0.5 or 0
	local halfSize = UDim2.new(target.Size.X.Scale * UNDERLINE_TRANSITION_SCALE, 0, 0, 3)
	local fullSize = UDim2.new(target.Size.X.Scale / 1.5, 0, 0, 3)
	
	local newPosition = UDim2.fromScale(target.Position.X.Scale + (target.Size.X.Scale / 2), 1)
	
	-- Tween size to be smaller
	if shouldAnimate then
		local halfSizeTween = API.Animate(underline, TweenInfo.new(
			UNDERLINE_TRANSITION_TIME / 2,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
		),
			{ Size = halfSize }
		)
		assert(halfSizeTween)
		halfSizeTween.Completed:Once(function()
			-- Return to original size
			API.Animate(underline, TweenInfo.new(
				UNDERLINE_TRANSITION_TIME / 2,
				Enum.EasingStyle.Exponential,
				Enum.EasingDirection.Out
				),
				{ Size = fullSize }
			)
		end)
	end
	
	-- Tween position
	API.Animate(underline, TweenInfo.new(
		UNDERLINE_TRANSITION_TIME,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		),
	{ Position = newPosition })
end

local function transitionSwitch(target: Frame, disabled: boolean)
	-- Disabled if transitioning to green
	disabled = not disabled
	-- I confused myself and now I don't know what disabled actually means I just know that it does the wrong thing if you don't invert it
	local switch = target:FindFirstChild("Switch") :: TextLabel
	API.Animate(switch,
		TweenInfo.new(
			0.25,
			Enum.EasingStyle.Quad
		), {
			Position = UDim2.fromScale(disabled and 0.9 or 0.1, 0.5)
		}
	)
	API.Animate(target,
		TweenInfo.new(
			0.25,
			Enum.EasingStyle.Quad
		), {
			BackgroundColor3 = disabled and Color3.fromRGB(189, 0, 0) or Color3.fromRGB(47, 189, 47)
		}
	)
	
	switch.Text = disabled and "O" or "I"
end
for i, v in createdTabs do
	local tab = tabBase:Clone() :: TextButton
	tab.Name = v
	tab.Text = v
	tab.Size = UDim2.fromScale(1 / #createdTabs, 1)
	tab.Position = UDim2.fromScale((i-1) / #createdTabs, 0)
	tab.Visible = true
	tab.LayoutOrder = i -- This is ordered more-or-less randomly, but the same random every time 
	tab.Parent = tabsFrame :: any
	
	local page = pageBase:Clone() :: GuiObject
	page.Name = "Page_"..v
	page.Parent = settingsFrame
	
	tab.MouseButton1Click:Connect(function()
		transitionUnderline(tabUnderline, tab)
		local currentPage
		for _, b in settingsFrame:GetChildren() do
			if (b.Name == "Page_"..settingsFrame:GetAttribute("CurrentTab")) then
				currentPage = b :: GuiObject
				break
			end
		end
		if settingsFrame:GetAttribute("CurrentTab") == v then
			return
		end
		API.TransitionUIPage(currentPage, (tabsFrame:FindFirstChild(currentPage.Name:sub(6)) :: GuiButton).LayoutOrder, page, tab.LayoutOrder, UDim2.fromScale(0, 0.1))
		settingsFrame:SetAttribute("CurrentTab", v)
	end)
	
	if i == 1 then
		page.Visible = true
		settingsFrame:SetAttribute("CurrentTab", v)
		transitionUnderline(tabUnderline, tab)
	end
end

local tt = settingsFrame.Parent.Tooltip
local function tooltip(text: string, pos: UDim2)
	tt.Position = pos
	tt.Text = text
	tt.Visible = true
end

local categories = {__len = 0}

local settingsParent = settingsFrame.Parent
local darken = settingsParent.LayoutDarken

local function done()
	local name = darken:GetAttribute("Setting")
	local displayName = darken:GetAttribute("DisplayName")
	SM.SetSetting(name, CAS:GetButton(displayName).Position)
	CAS:UnbindAction(displayName)
	settingsParent.Main.Visible = true
	settingsParent.Close.Visible = true
	settingsParent.Tooltip.Visible = true
	darken.Visible = false
end

UIS.TouchTap:Connect(function(posVectors, proc)
	if proc then return end
	if not darken.Visible then return end
	if darken:GetAttribute("OpenedAt") > (os.time() - 0.001) then return end -- For some reason taps are sometimes detected immediately after
	local name = darken:GetAttribute("DisplayName")
	local posVector: Vector2 = posVectors[1]

	local inset = GUI:GetGuiInset()
	local pos = UDim2.fromOffset(posVector.X + inset.X, posVector.Y + inset.Y)
	CAS:GetButton(name).Position = pos
end)

darken.Done.MouseButton1Click:Connect(done)

settingsFrame.Parent:GetPropertyChangedSignal("Visible"):Connect(function()
	if not settingsFrame.Parent.Visible then
		ReplicatedStorage.ClientServer.SaveSettings:FireServer(SM.JSONEncode())
	end
end)

local keybindingCons = {}
for _, setting: SM.SettingDefinition in SM.AvailableSettings do
	local tab = setting.Tab
	local settingType = setting.PossibleValues
	local name = setting.Name
	local page = settingsFrame:FindFirstChild("Page_"..tab)
	
	local cat = setting.Category
	local catIndex = tab.."_"..cat
	if not categories[catIndex] then
		categories[catIndex] = 0
		
		local label = pageBase.CategoryLabel:Clone() :: TextLabel
		label.Text = cat
		label.LayoutOrder = categories["__len"]*1000
		label.Visible = true
		label.Name = "Category_"..cat
		label.Parent = page
		categories["__len"] += 1
	end
	local catLabel = page:FindFirstChild("Category_"..cat) :: TextLabel
	categories[catIndex] += 1
	
	local f: GuiObject
	if settingType == "Boolean" then
		local frame = booleanFrame:Clone() :: typeof(booleanFrame)
		local val = frame.Value
		transitionSwitch(val, SM.GetSetting(name) :: boolean)
		
		frame.Label.Text = name..":"
		
		frame.MouseButton1Click:Connect(function()
			local newVal = not SM.GetSetting(name)
			SM.SetSetting(name, newVal)
			transitionSwitch(frame.Value, newVal)
		end)
		f = frame
	elseif type(settingType) == "table" then
		local frame = selectorFrame:Clone() :: typeof(selectorFrame)
		frame.Label.Text = name..":"
		
		local opts = {}
		for i, v in settingType do
			local selections = frame.Selections
			
			local opt = selections.__Option:Clone()
			opt.Name = v
			opt.Text = v
			opt.Visible = true
			opt.Position = UDim2.fromScale((i-1) / #settingType, 0)
			
			local selectionUnderline = selections.Underline
			if SM.GetSetting(setting.Name) == v then
				transitionUnderline(selectionUnderline, opt)
			end
			
			opt.Parent = selections
			
			table.insert(opts, opt)
			opt.MouseButton1Click:Connect(function()
				SM.SetSetting(name, v)
				for _, p in opts do
					p.Text = p.Name
				end
				transitionUnderline(selectionUnderline, opt)
				opt.Text = v
			end)
		end
		f = frame
	elseif settingType == "Keybind" then
		local frame = keybindFrame:Clone()
		local m = frame.Frame
		m.Label.Text = name..":"
		
		local setBinds = SM.GetSetting(name) :: SM.KeybindSetting
		
		local function updateBinds(binds: any)
			local numBoundKeys = 0
			for _, v in m.Keybinds:GetChildren() do
				if v:IsA("Frame") and (v.Name ~= "__KeybindFrame") then
					numBoundKeys += 1
				end
			end
			for i, v: {SM.Keybind} in binds do
				local bind = m.Keybinds.__KeybindFrame:Clone()
				
				bind.LayoutOrder = (i + numBoundKeys)*2 -- Separator in between, hence *2

				bind.Name = name..tostring(i + numBoundKeys)
				
				local result = Controls.GetStringForKeyCode(v[1])
				if result:sub(1, 11) == "rbxasset://" then
					local img = bind.KeycodeImage
					img.Image = result
					img.Visible = true
					bind.Keycode.Visible = false
				else
					bind.Keycode.Text = result
				end

				if v[2] then
					bind.Modifier.Text = Controls.GetStringForKeyCode(v[2])
					bind.Modifier.Visible = true
					bind.Plus.Visible = true
				end

				bind.Visible = true
				bind.Parent = m.Keybinds

				if (numBoundKeys+i) > 1 then
					local sep = m.Keybinds.__Separator:Clone()
					sep.Name = "Separator"
					sep.Visible = true
					sep.LayoutOrder = bind.LayoutOrder-1
					sep.Name = "Separator"..tostring(sep.LayoutOrder)
					sep.Parent = m.Keybinds
				end

				local function removeBind()
					local binds = SM.GetSetting(name) :: any
					table.remove(binds.Keycodes, table.find((binds :: any).Keycodes, setBinds))
					SM.SetSetting(name, binds)

					bind:Destroy()
					local sep
					if bind.Name:split(name)[2] == "1" then
						sep = m.Keybinds:FindFirstChild("Separator"..tostring(bind.LayoutOrder+1))
					else
						sep = m.Keybinds:FindFirstChild("Separator"..tostring(bind.LayoutOrder-1))
					end
					
					if sep then sep:Destroy() end
				end
				
				bind.KeycodeImage.MouseButton1Click:Connect(removeBind)
				bind.Keycode.MouseButton1Click:Connect(removeBind)
				bind.Modifier.MouseButton1Click:Connect(removeBind)
			end
		end
		
		updateBinds(setBinds.Keycodes)
		
		if setting.SpecifyToggle then
			local toggleButton = m.Toggled
			toggleButton.Visible = true
			toggleButton.Image = (SM.GetSetting(name)::any).Toggled and "rbxassetid://9155626912" or "rbxassetid://9155599240"
			toggleButton.MouseButton1Click:Connect(function()
				local cur = SM.GetSetting(name) :: any
				cur.Toggled = not cur.Toggled
				SM.SetSetting(name, cur)
				
				toggleButton.Image = cur.Toggled and "rbxassetid://9155626912" or "rbxassetid://9155599240"
			end)
		end
		
		frame.ClickDetector.MouseButton1Click:Connect(function()
			for _, v: any in keybindingCons do v:Disconnect() end
			local msg = API.ScreenMessage("Info", "Press F5 to cancel keybinding.\nYou can also add a modifier key, such as Shift or Ctrl.")
			CAS:BindActionAtPriority("SelectKeybind", function(_, state, input)
				
				if state ~= Enum.UserInputState.End then return end
				if (input.KeyCode == Enum.KeyCode.F5) then
					API.ScreenMessage("Info", "Cancelled keybinding.")
					if msg then msg:Destroy() end
					CAS:UnbindAction("SelectKeybind")
				end

				local t = {((input.KeyCode ~= Enum.KeyCode.Unknown) and input.KeyCode) or input.UserInputType}
				for _, v in {Enum.KeyCode.LeftControl, Enum.KeyCode.LeftShift, Enum.KeyCode.LeftAlt, Enum.KeyCode.RightControl, Enum.KeyCode.RightShift, Enum.KeyCode.RightAlt} do
					if UIS:IsKeyDown(v) then
						table.insert(t, v)
						break
					end
				end
				local cur = SM.GetSetting(name) :: any
				table.insert(cur.Keycodes, t)
				SM.SetSetting(name, cur)
				if msg then msg:Destroy() end
				updateBinds({t})
				API.ScreenMessage("Success", "Keybinding updated!")
				CAS:UnbindAction("SelectKeybind")
				return
			end, false, 100000, Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.Keyboard, Enum.UserInputType.Gamepad1, Enum.UserInputType.MouseButton3)
		end)
		f = frame
	elseif settingType == "TouchPosition" then
		local frame = touchFrame:Clone()
		frame.Label.Text = name
		frame.MouseButton1Click:Connect(function(): any
			if not UIS.TouchEnabled then
				return API.ScreenMessage("Info", "You must have touchscreen enabled to use this.")
			end
			darken:SetAttribute("Setting", name)
			darken:SetAttribute("OpenedAt", workspace:GetServerTimeNow())
			local name = name:split(" Position")[1]
			darken:SetAttribute("DisplayName", name)
			CAS:BindAction(name, function() return end, true)
			Controls.SetupTouchButton(name)
			
			settingsParent.Main.Visible = false
			settingsParent.Close.Visible = false
			settingsParent.Tooltip.Visible = false
			darken.Visible = true
			return
		end)
		f = frame
	elseif settingType == "TouchScale" then
		local frame = touchFrame:Clone()
		frame.Label.Text = name
		frame.MouseButton1Click:Connect(function(): any
			if not UIS.TouchEnabled then
				return API.ScreenMessage("Info", "You must have touchscreen enabled to use this.")
			end
			local newScale = require(ReplicatedFirst.TextInput).Create(name, "Number", "0.1-10", "TouchScale")
			if newScale then
				SM.SetSetting(name, newScale)
			end
			local name = name:split(" Scale")[1]
			CAS:BindAction(name, function() return end, true)
			Controls.SetupTouchButton(name)
			return
		end)
		f = frame
	end
	
	if not f then
		continue
	end
	
	f.Visible = true
	f.LayoutOrder = catLabel.LayoutOrder + categories[catIndex]
	f.Name = name
	f.Parent = settingsFrame:FindFirstChild("Page_"..tab)
	
	local help = f:FindFirstChild("Help") :: TextButton
	help.MouseButton1Click:Connect(function()
		local newPos = UDim2.new(0.05, help.AbsolutePosition.X, 0, help.AbsolutePosition.Y)
		if (newPos == tt.Position) and (tt.Visible) then
			tt.Visible = false
			return
		end
		tooltip(setting.Tooltip, newPos)
	end)
end