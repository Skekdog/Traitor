local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)

local module = {}

function module.Animate(object: Instance, tweenInfo: TweenInfo, properties: {[string]: any}, noAnimate: boolean?): Tween?
	local animate = not GuiService.ReducedMotionEnabled and Settings.GetSetting("Animate UI")

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

function module.TransitionUIState(frame: GuiObject, open: boolean): Tween?
	-- If open is true, open animation should play, otherwise close

	local tween: Tween?
	local style = frame:GetAttribute("TransitionStyle")
	if style == "Position" or style == "Size" then
		local isSize = frame:GetAttribute("TransitionStyle") == "Size"
		local targetUDim = frame:GetAttribute("TransitionTarget") :: UDim2

		local direction = frame:GetAttribute("TransitionDirection") -- The direction it moves when OPENING
		local offScreenPosition = targetUDim
		if direction == "Right" then
			offScreenPosition = UDim2.new((frame.Size.X.Scale * frame.AnchorPoint.X) - frame.Size.X.Scale, targetUDim.X.Offset, targetUDim.Y.Scale, targetUDim.Y.Offset)
		elseif direction == "Left" then
			offScreenPosition = UDim2.new((frame.Size.X.Scale * frame.AnchorPoint.X) + 1, targetUDim.X.Offset, targetUDim.Y.Scale, targetUDim.Y.Offset)
		elseif direction == "Up" then
			offScreenPosition = UDim2.new(targetUDim.X.Scale, targetUDim.X.Offset, (frame.Size.Y.Scale * frame.AnchorPoint.Y) + 1, targetUDim.Y.Offset)
		elseif direction == "Down" then
			offScreenPosition = UDim2.new(targetUDim.X.Scale, targetUDim.X.Offset, (frame.Size.Y.Scale * frame.AnchorPoint.Y) - 1, targetUDim.Y.Offset)
		elseif not isSize then
			error("Invalid direction for " .. frame.Name)
		end

		local UI_TRANSITION_TIME = if isSize then 0.2 else 0.4
		local UI_SCALE_FACTOR = 0.75

		local scale = frame:FindFirstChild("UIAnimationScale")
		if not scale then
			local newScale = Instance.new("UIScale")
			newScale.Name = "UIAnimationScale"
			newScale.Parent = frame
			scale = newScale
		end

		if isSize then
			assert(scale and scale:IsA("UIScale"), "Expected UIAnimationScale to be a UIScale")
		end

		local function onFinish(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Cancelled then
				return
			end

			if open then
				if isSize then
					assert(scale and scale:IsA("UIScale"))
					scale.Scale = 1
				else
					frame.Position = targetUDim
				end
			else
				frame.Visible = false
				if isSize then
					assert(scale and scale:IsA("UIScale"))
					scale.Scale = UI_SCALE_FACTOR
				else
					frame.Position = offScreenPosition
				end
			end
		end

		local info = TweenInfo.new(
			UI_TRANSITION_TIME,
			Enum.EasingStyle.Exponential,
			if isSize then Enum.EasingDirection.Out else Enum.EasingDirection.InOut
		)

		local properties: {[string]: any}
		if isSize then
			properties = {
				Scale = if open then 1 else UI_SCALE_FACTOR
			}
		else
			properties = {
				Position = if open then targetUDim else offScreenPosition
			}
		end

		tween = module.Animate(if isSize then scale :: UIScale else frame, info, properties)

		if open then
			if isSize then
				assert(scale and scale:IsA("UIScale"))
				scale.Scale = UI_SCALE_FACTOR
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
			tween.Completed:Once(onFinish)
		else
			onFinish(Enum.PlaybackState.Completed)
		end
	elseif style == "Transparency" then
		local lastTween: Tween?
		for _, v in frame:GetDescendants() do
			local property
			if v:IsA("ImageLabel") then
				property = "ImageTransparency"
			elseif v:IsA("Frame") then
				property = "BackgroundTransparency"
			else
				continue
			end

			if open then
				(v :: any)[property] = 1
			end

			local properties = {[property] = if open then 0 else 1}
			tween = module.Animate(v, TweenInfo.new(0.25, Enum.EasingStyle.Quad), properties)

			if tween then
				lastTween = tween
				tween.Completed:Once(function()
					if open then
						(v :: any)[property] = 0
					else
						(v :: any)[property] = 1
					end
				end)
			end
		end

		if open then
			frame.Visible = true
		end

		if lastTween and not open then
			lastTween.Completed:Once(function()
				frame.Visible = false
			end)
		end
	end

	return tween
end

function module.TransitionSwitch(target: GuiObject, disabled: boolean)
	disabled = not disabled -- ???
	local switch = target:FindFirstChild("Switch")

	assert(switch and switch:IsA("TextLabel"))

	local lastPosTween = switch:FindFirstChild("PositionTween")
	local lastColourTween = switch:FindFirstChild("ColourTween")

	if lastPosTween then
		assert(lastPosTween:IsA("Tween"))
		lastPosTween:Cancel()
		lastPosTween:Destroy()
	end

	if lastColourTween then
		assert(lastColourTween:IsA("Tween"))
		lastColourTween:Cancel()
		lastColourTween:Destroy()
	end

    local posTween = module.Animate(switch, TweenInfo.new(0.25, Enum.EasingStyle.Quad),
		{
			Position = UDim2.fromScale(if disabled then 0.1 else 0.9, 0.5)
		}
	)

	local colourTween = module.Animate(target,
		TweenInfo.new(
			0.25,
			Enum.EasingStyle.Quad
		), {
			BackgroundColor3 = disabled and Color3.fromRGB(189, 0, 0) or Color3.fromRGB(47, 189, 47)
		}
	)

	if posTween then
		posTween.Name = "PositionTween"
		posTween.Parent = switch
	end

	if colourTween then
		colourTween.Name = "ColourTween"
		colourTween.Parent = switch
	end

	switch.Text = if disabled then "O" else "I"
end

local pageTransitionTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
function module.TransitionUIPage(currentPage: GuiObject, newPage: GuiObject, targetPosition: UDim2): ()
	assert(currentPage.LayoutOrder ~= newPage.LayoutOrder, `I forgor 💀 (Page transition failed for {currentPage:GetFullName()})`)
	local goRight = currentPage.LayoutOrder < newPage.LayoutOrder

	local targetPositionForCurrent
	if goRight then
		targetPositionForCurrent = UDim2.new(targetPosition.X - currentPage.Size.X, newPage.Position.Y)
		newPage.Position = UDim2.new(targetPosition.X + newPage.Size.X, newPage.Position.Y)
	else
		targetPositionForCurrent = UDim2.new(targetPosition.X + currentPage.Size.X, newPage.Position.Y)
		newPage.Position = UDim2.new(targetPosition.X - newPage.Size.X, newPage.Position.Y)
	end

	newPage.Visible = true
	module.Animate(newPage, pageTransitionTweenInfo, { Position = targetPosition })

	local tween = module.Animate(currentPage, pageTransitionTweenInfo, { Position = targetPositionForCurrent })
	if tween then
		tween:GetPropertyChangedSignal("PlaybackState"):Connect(function()
			if tween.PlaybackState == Enum.PlaybackState.Completed then
				currentPage.Visible = false
			end
		end)
	else
		currentPage.Visible = false
	end
end

local underlineConnections: {[Frame]: {RBXScriptConnection}?} = {}
local UNDERLINE_TRANSITION_SCALE = 0.125
local UNDERLINE_TRANSITION_TIME = 0.5

local function calculatePositionAndSize(relativeParent: GuiObject, target: GuiObject, underlineSizeY: number): (UDim2, UDim2)
	local size = UDim2.fromOffset(target.AbsoluteSize.X / 1.5, underlineSizeY)

	local posX = target.AbsolutePosition.X - relativeParent.AbsolutePosition.X + target.AbsoluteSize.X / 2
	local posY = target.AbsolutePosition.Y - relativeParent.AbsolutePosition.Y + target.AbsoluteSize.Y + underlineSizeY

	local position = UDim2.fromOffset(posX, posY)

	return position, size
end

function module.TransitionUnderline(underline: Frame, target: TextButton): ()
	local relativeParent = underline:FindFirstAncestorWhichIsA("GuiObject")
	assert(relativeParent, "Could not find positioning parent for underline")

	underline.AnchorPoint = Vector2.new(0.5, 1)

	local underlineSizeY = 2
	local newPosition, fullSize = calculatePositionAndSize(relativeParent, target, underlineSizeY)

	local halfSize = UDim2.new(fullSize.X.Scale * UNDERLINE_TRANSITION_SCALE, fullSize.X.Offset * UNDERLINE_TRANSITION_SCALE, fullSize.Y.Scale, fullSize.Y.Offset)

	local halfSizeTween = module.Animate(underline, TweenInfo.new(
		UNDERLINE_TRANSITION_TIME / 2,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
	),
		{ Size = halfSize }
	)

	local function originalSize()
		module.Animate(underline, TweenInfo.new(
			UNDERLINE_TRANSITION_TIME / 2,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
			),
			{ Size = fullSize }
		)
	end
	if halfSizeTween then
		halfSizeTween.Completed:Once(originalSize)
	else
		originalSize()
	end

	local oldConns = underlineConnections[underline]
	if oldConns then
		for _, v in oldConns do
			v:Disconnect()
		end
	end

	local tween = module.Animate(underline, TweenInfo.new(
		UNDERLINE_TRANSITION_TIME,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		),
	{ Position = newPosition })

	local function recalculatePositioning(): ()
		underline.Position, underline.Size = calculatePositionAndSize(relativeParent, target, underlineSizeY)

		if tween and tween.PlaybackState == Enum.PlaybackState.Playing then
			tween:Cancel()
		end
	end

	underlineConnections[underline] = {target:GetPropertyChangedSignal("AbsoluteSize"):Connect(recalculatePositioning), target:GetPropertyChangedSignal("AbsolutePosition"):Connect(recalculatePositioning)}
end

function module.Slider(background: Frame, noTransition: boolean?, value: number, max: number): ()
	local size = if value == max or max == 0 then 1 else value / max -- condition needed for case where value or max is infinity
	module.Animate(background, TweenInfo.new(0.1), {Size = UDim2.new(size, 0, 1, 0)}, noTransition)
end

return table.freeze(module)