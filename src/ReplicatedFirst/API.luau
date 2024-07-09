local TweenService = game:GetService("TweenService")
local SettingsManager = require(script.Parent.SettingsManager)

local plr = game:GetService("Players").LocalPlayer

local screenMessageFormats = {
	Standard = {
		Name = "Standard",
		LabelProperties = {
			Text = "Standard Message",
			TextScaled = true,
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeColor3 = Color3.new(0, 0, 0),
			FontFace = Font.fromName("Ubuntu"),
			BackgroundTransparency = 1,
			RichText = false, -- If enabled, UIStroke does not apply
		}
	},
	Error = {
		Name = "Error",
		InheritsFrom = "Standard",
		LabelProperties = {
			Text = "Error Message",
			TextColor3 = Color3.new(1, 0, 0)
		},
	},
	Info = {
		Name = "Info",
		InheritsFrom = "Standard",
		LabelProperties = {
			Text = "Info Message",
			TextColor3 = Color3.new(0.125, 0.5, 1)
		}
	},
	Success = {
		Name = "Success",
		InheritsFrom = "Standard",
		LabelProperties = {
			Text = "Success Message",
			TextColor3 = Color3.new(0, 0.71, 0)
		}
	},
	Warn = {
		Name = "Warn",
		InheritsFrom = "Standard",
		LabelProperties = {
			Text = "Warning Message",
			TextColor3 = Color3.new(1, 0.48, 0.13)
		}
	}
}

local module = {}

function module.LerpNumber(num1: number, num2: number, decimal: number): number --Linearly interpolates a number
	return num1 + ((num2 - num1) * decimal)
end

local vowels = {"a", "e", "i", "o", "u"}
function module.StringWithDeterminer(str: string): string
	local lowered = str:lower()

	local determiner = "a "
	if table.find(vowels, lowered:sub(1)) then
		determiner = "an "
	end

	return determiner..str
end

function module.ScreenMessage(format: string, text: string, formatOverrides: {[string]: any}?): TextLabel
	local label = Instance.new("TextLabel")
	
	local inheritanceOrder = {}
	
	do
		local inheritanceStep = format
		repeat
			table.insert(inheritanceOrder, 1, inheritanceStep)
			inheritanceStep = screenMessageFormats[inheritanceStep].InheritsFrom
		until not inheritanceStep
		
		if formatOverrides then
			inheritanceOrder[#inheritanceOrder + 1] = "__formatOverride"
		end
	end
	
	for _, formatName in inheritanceOrder do
		local formatTable = formatName == "__formatOverride" and formatOverrides or screenMessageFormats[formatName]
		
		if formatTable.LabelProperties then
			for i, v in formatTable.LabelProperties do
				(label :: any)[i] = v
			end
		end
	end
	
	label.Text = text

	local gui: Frame = (plr :: any).PlayerGui.Special.ScreenMessage
	label.Size = UDim2.fromScale(0.8, 0.05)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.fromScale(0.5, 0.05 * (#gui:GetChildren() + 1))

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label

	label.Parent = gui
	
	local tween = TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 3), {
		BackgroundTransparency = 1,
		TextTransparency = 1,
	})
	tween.Completed:Once(function()
		for _, v: any in gui:GetChildren() do
			local foundTween = v:FindFirstChildOfClass("Tween")
			if foundTween then
				foundTween:Cancel()
				foundTween:Destroy()
			end
			local tween = TweenService:Create(v, TweenInfo.new(0.5), {
				Position = UDim2.fromScale(0.5, v.Position.Y.Scale - 0.05)
			})
			tween.Parent = v
			tween:Play()
		end
		label:Destroy()
	end)
	tween:Play()
	
	return label
end

function module.Animate(object: Instance, tweenInfo: TweenInfo, properties: {[string]: any}, noAnimate: boolean?): Tween?
	local animate = SettingsManager.GetSetting("Animate UI Transitions")

	if not animate or noAnimate then
		for i, v in properties do
			(object :: any)[i] = v
		end
		return
	end
	local tween = TweenService:Create(object, tweenInfo, properties)
	tween:Play()
	return tween
end

function module.TransitionUIPage(currentPage: GuiObject, currentPageOrder: number, newPage: GuiObject, newPageOrder: number, targetPosition: UDim2)
	-- If new page is to the right, then the new page should be positioned on the right
	-- and current page should slide to the left
	local goRight = newPageOrder > currentPageOrder
	
	local targetPositionForCurrent
	-- Can't do anything smart with * -1, because UDim2 does not support multiplication
	if goRight then
		newPage.Position = UDim2.new(targetPosition.X + currentPage.Size.X, newPage.Position.Y)
		targetPositionForCurrent = UDim2.new(targetPosition.X - currentPage.Size.X, newPage.Position.Y)
	else
		newPage.Position = UDim2.new(targetPosition.X - currentPage.Size.X, newPage.Position.Y)
		targetPositionForCurrent = UDim2.new(targetPosition.X + currentPage.Size.X, newPage.Position.Y)
	end
	
	newPage.Visible = true
	module.Animate(newPage, TweenInfo.new(0.2,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.In
		),
		{
			Position = currentPage.Position
		}
	)
	local animTween = module.Animate(currentPage, TweenInfo.new(0.2,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.In
		),
		{
			Position = targetPositionForCurrent
		}
	)
	if animTween then
		animTween:GetPropertyChangedSignal("PlaybackState"):Connect(function()
			if animTween.PlaybackState ~= Enum.PlaybackState.Playing then
				currentPage.Position = targetPositionForCurrent
				newPage.Position = targetPosition
				animTween:Destroy()
			end
		end)	
	end
end

function module.ToRoundTime(time: number, target: number): string
	local diffTime = math.max(math.round(target) - math.round(time), 0)
	local minutes = tostring(diffTime // 60)
	local seconds = tostring(diffTime % 60)

	if string.len(minutes) < 2 then
		minutes = "0"..minutes
	end
	if string.len(seconds) < 2 then
		seconds = "0"..seconds
	end

	return minutes..":"..seconds
end

function module.TransitionUIState(frame: GuiObject, open: boolean)
	-- If open is true, open animation should play, otherwise close
	
	local oldTween = frame:FindFirstChild("StateTransitionTween") :: Tween
	if oldTween then
		oldTween:Cancel()
		oldTween:Destroy()
	end

	local isSize = frame:GetAttribute("TransitionStyle") == "Size"
	local targetUDim = frame:GetAttribute("TransitionTarget")
	local offScreenPosition = UDim2.fromScale(targetUDim.X.Scale, -frame.Size.Y.Scale)

	local function onFinish()
		if open then
			if isSize then
				frame.Size = targetUDim
			else
				frame.Position = targetUDim
			end
		else
			frame.Visible = false
			if isSize then
				frame.Size = UDim2.new()
			else
				frame.Position = offScreenPosition
			end
		end
	end
	
	local UI_TRANSITION_TIME = if open then 0.2 else tonumber(SettingsManager.GetSetting("Close Speed")) :: number
	local UI_SCALE_FACTOR = tonumber(SettingsManager.GetSetting("Close Scale"))
	
	
	local startSize = UDim2.new(targetUDim.X.Scale * UI_SCALE_FACTOR, targetUDim.X.Offset * UI_SCALE_FACTOR, targetUDim.Y.Scale * UI_SCALE_FACTOR, targetUDim.Y.Offset * UI_SCALE_FACTOR)
	
	local info = TweenInfo.new(
		UI_TRANSITION_TIME,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
	)
	
	local properties
	if isSize then
		properties = {
			Size = open and targetUDim or startSize
		}
	else
		properties = {
			Position = open and targetUDim or offScreenPosition
		}
	end
	
	local tween = module.Animate(frame, info, properties)
	
	if open then
		if isSize then
			frame.Size = startSize
		else
			frame.Position = offScreenPosition
		end
		frame.Visible = true
	end
	
	local modalise = frame:FindFirstChild("Modalise") :: TextButton
	if modalise then
		modalise.Visible = open
	end

	if tween then
		tween.Completed:Once(function()
			tween:Destroy()
			onFinish()
		end)
		tween.Name = "StateTransitionTween"
		tween.Parent = frame
	else
		onFinish()
	end
end

return module