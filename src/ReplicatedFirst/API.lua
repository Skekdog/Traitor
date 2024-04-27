local TS = game:GetService("TweenService")

local plr = game:GetService("Players").LocalPlayer

local screenMessageFormats = {
	Standard = {
		Name = "Standard",
		LabelProperties = {
			Text = "Standard Message",
			TextScaled = true,
			TextColor3 = Color3.new(1,1,1),
			TextStrokeColor3 = Color3.new(0,0,0),
			TextStrokeTransparency = 0.5,
			FontFace = Font.fromName("SourceSansPro",Enum.FontWeight.Medium,Enum.FontStyle.Normal),
			BackgroundTransparency = 0.5,
			RichText = true,

			Size = UDim2.fromScale(0.2,0.1),
			Position = UDim2.fromScale(0.5,0),
			AnchorPoint = Vector2.new(0.5,0.5),
		},
		TweenProperties = {  -- time, easingStyle, easingDirection, repeatCount, reverses, delayTime
			3,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out,
			0,
			false,
			5
		}
	},
	Error = {
		Name = "Error",
		InheritsFrom = "Standard",
		LabelProperties = {
			Text = "Error Message",
			TextColor3 = Color3.new(1,0,0),
			TextStrokeColor3 = Color3.new(0.9,0.9,0.9)
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
			TextColor3 = Color3.new(0,0.71,0),
			TextStrokeColor3 = Color3.new(0.5,0.5,0.5)
		}
	},
	Warn = {
		Name = "Warn",
		InheritsFrom = "Standard",
		LabelProperties = {
			Text = "Warning Message",
			TextColor3 = Color3.new(1,0.48,0.13)
		}
	},
	NiceTry = {
		Name = "NiceTry",
		InheritsFrom = "Error",
		LabelProperties = {
			Text = "Nice try.",
			TextStrokeColor3 = Color3.new(0.314,0.047,0.047)
		}
	}
}

local module = {}

function module.ReverseList(list:{}): {} --Reverses the order of a list
	local reversedList = {}
	for i = #list,1,-1 do
		table.insert(reversedList,list[i])
	end
	return reversedList
end

function module.ShuffleList(list:{}): {} --Randomly shuffles a list using the Fisher-Yates algorithm
	math.randomseed(workspace:GetServerTimeNow())
	local shuffledList = {}
	for _,v in ipairs(list) do
		local pos = math.random(1,#shuffledList+1)
		table.insert(shuffledList,pos,v)
	end
	return shuffledList
end

function module.LerpNumber(num1:number,num2:number,decimal:number): number --Linearly interpolates a number
	return num1 + ((num2 - num1) * decimal)
end

function module.HexToColor3(hex:string):Color3 --Credit: @Blockzez
	local r,g,b = string.match(hex, "^#?(%w%w)(%w%w)(%w%w)$")
	return Color3.fromRGB(tonumber(r,16),tonumber(g,16),tonumber(b,16))
end

function module.Color3ToHex(color:Color3):string --Credit: @Blockzez
	return string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
end

function module.ScreenMessage(format: string, text: string, formatOverrides: {}?): TextLabel
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
	
	local tweenParams = {}
	
	for _, formatName in inheritanceOrder do
		local formatTable = formatName == "__formatOverride" and formatOverrides or screenMessageFormats[formatName]
		
		if formatTable.LabelProperties then
			for i, v in formatTable.LabelProperties do
				label[i] = v
			end
		end
		
		if formatTable.TweenProperties then
			for i, v in formatTable.TweenProperties do
				tweenParams[i] = v
			end
		end
	end
	
	label.Text = text
	label.Parent = plr.PlayerGui.Special:WaitForChild("ScreenMessage")
	
	local tween = TS:Create(label, TweenInfo.new(table.unpack(tweenParams)), {
		Position = UDim2.fromScale(0.5, -0.5)
	})
	tween.Completed:Once(function()
		label:Destroy()
	end)
	tween:Play()
	
	return label
end

function module.WaitForChildOfClass(instance:Instance,className:string,timeout:number?):Instance?
	if typeof(instance) ~= "Instance" then error("Expected Instance in Instance of WaitForChildOfClass, got "..typeof(instance)) end
	if typeof(className) ~= "string" then error("Expected string for className of WaitForChildOfClass, got "..typeof(className)) end
	if not table.find({"number","nil"},typeof(timeout)) then error("Expected number or nil for timeout of WaitForChildOfClass, got "..typeof(timeout)) end
	local start = os.time()
	local endTime = start+(timeout or math.huge)
	local warned = false
	repeat
		task.wait()
		if not timeout and not warned then
			if start+5 <= os.time() then
				warned = true
				warn("Infinite yield possible on "..instance.Name..":WaitForChildOfClass("..className..")")
			end
		end
	until instance:FindFirstChildOfClass(className) or os.time()>=endTime
	return instance:FindFirstChildOfClass(className)
end

function module.FindFirstChildSplit(instance:Instance,split:string,target:string,index:number): Instance?
	if typeof(instance) ~= "Instance" then error("Expected Instance in Instance of MatchFirstChild, got "..typeof(instance)) end
	if typeof(split) ~= "string" then error("Expected string for split of FindFirstChildSplit, got "..typeof(split)) end
	if typeof(target) ~= "string" then error("Expected string for target of FindFirstChildSplit, got "..typeof(target)) end
	if typeof(index) ~= "number" then error("Expected number for index of FindFirstChildSplit, got "..typeof(index)) end
	for _,v in instance:GetChildren() do
		if v.Name:split(split)[index] == target then return v end
	end
	return nil
end


function module.TransitionUIPage(currentPage: Frame, currentPageOrder: number, newPage: Frame, newPageOrder: number, targetPosition: UDim2)
	local requestSetting = script.Parent.SettingsManager:FindFirstChild("RequestSetting")
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
	
	local UI_PAGE_TRANSITION_TIME = requestSetting:Invoke("Animate UI Transitions") and 0.2 or 0 
	TS:Create(newPage, TweenInfo.new(UI_PAGE_TRANSITION_TIME,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.In
		),
		{
			Position = currentPage.Position
		}
	):Play()
	local animTween = TS:Create(currentPage, TweenInfo.new(UI_PAGE_TRANSITION_TIME,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.In
		),
		{
			Position = targetPositionForCurrent
		}
	)
	animTween:GetPropertyChangedSignal("PlaybackState"):Connect(function()
		if animTween.PlaybackState ~= Enum.PlaybackState.Playing then
			currentPage.Position = targetPositionForCurrent
			newPage.Position = targetPosition
			animTween:Destroy()
		end
	end)
	animTween:Play()
end

function module.TransitionUIState(frame: Frame, open: boolean)
	-- If open is true, open animation should play, otherwise close
	local requestSetting = script.Parent.SettingsManager:FindFirstChild("RequestSetting")
	
	local oldTween: Tween = frame:FindFirstChild("StateTransitionTween") :: Tween
	if oldTween then
		oldTween:Cancel()
		oldTween:Destroy()
	end
	
	local UI_TRANSITION_TIME = requestSetting:Invoke("Animate UI Transitions") and 0.2 or 0
	local UI_SCALE_FACTOR = 0.75
	
	local isSize = frame:GetAttribute("TransitionStyle") == "Size"
	
	local targetUDim = frame:GetAttribute("TransitionTarget")
	local startSize = UDim2.new(targetUDim.X.Scale * UI_SCALE_FACTOR, targetUDim.X.Offset * UI_SCALE_FACTOR, targetUDim.Y.Scale * UI_SCALE_FACTOR, targetUDim.Y.Offset * UI_SCALE_FACTOR)
	
	local info = TweenInfo.new(
		UI_TRANSITION_TIME,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
	)
	
	local offScreenPosition = UDim2.fromScale(targetUDim.X.Scale, -frame.Size.Y.Scale)
	
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
	
	local tween = TS:Create(frame, info, properties)
	
	if open then
		if isSize then
			frame.Size = startSize
		else
			frame.Position = offScreenPosition
		end
		frame.Visible = true
	end
	
	local modalise = frame:FindFirstChild("Modalise")
	if modalise then
		modalise.Visible = open
	end
	
	tween.Completed:Once(function()
		tween:Destroy()
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
	end)
	
	tween.Name = "StateTransitionTween"
	tween.Parent = frame
	
	tween:Play()
end

return module

