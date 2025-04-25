local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.RoundRule.Types)

local MIN_ARM_DURATION = 10
local MAX_ARM_DURATION = 360

type C4 = Types.Interactable & {
	Extras: {
		ArmId: never?,
		ArmedBy: Types.Participant?,
		SafeWires: {number}?,
		ArmDurationClient: number?,
		BeganBeepingClient: boolean?,
		[any]: never,
	}
}

local function getTimerText(timeLeft: number): string
	if timeLeft < 0 then
		timeLeft = 0
	end

	local minutes = math.floor(timeLeft / 60)
	local seconds = timeLeft % 60

	local text = string.format("%02d:%02d", minutes, seconds)
	return text
end

local remote: RemoteEvent
if RunService:IsServer() then
	remote = Instance.new("RemoteEvent")
	remote.Name = "C4Interact"
	remote.Parent = script
else
	local found = script:WaitForChild("C4Interact")
	assert(found:IsA("RemoteEvent"), "C4Interact must be a RemoteEvent")
	remote = found
end

local currentC4: C4?
local function getC4Menu()
	local UIManager = require(ReplicatedStorage.UIManager)
	local ui = UIManager.WaitForUI("C4Menu") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.C4Menu)}
	return ui
end

local function isArmedClient(c4: C4): boolean
	return c4.Object:GetAttribute("ExplodesAt") ~= nil
end

local function setDuration(c4: C4, percent: number): ()
	local ui = getC4Menu()
	local sliderBar = ui.Object.Arm.Arm.SliderBar

	local duration = math.lerp(MIN_ARM_DURATION, MAX_ARM_DURATION, percent)
	sliderBar.Slider.Position = UDim2.fromScale(percent, 0.5)
	ui.Object.SidePanel.Timer.Text = getTimerText(duration)

	c4.Extras.ArmDurationClient = duration
end

local isFirstInit = true
local function showC4Menu(c4: C4, show: boolean): ()
	currentC4 = c4
	assert(currentC4)

	local WalkSpeed = require(ReplicatedStorage.WalkSpeed)
	local JumpPower = require(ReplicatedStorage.JumpPower)

	local ui = getC4Menu()
	local buttons = ui.Object.SidePanel.Buttons

	if show then
		ui.Object.Wires.Visible = isArmedClient(c4)
		ui.Object.Arm.Visible = not isArmedClient(c4)
	end

	if show and not isArmedClient(currentC4) then
		setDuration(currentC4, 0)
	end

	WalkSpeed.SetModifier("C4Menu", if show then -math.huge else 0)
	JumpPower.SetModifier("C4Menu", not show)

	buttons.Arm.Visible = not isArmedClient(c4)
	buttons.Take.Visible = not isArmedClient(c4)
	buttons:FindFirstChild("Destroy").Visible = not isArmedClient(c4)

	if isFirstInit then
		buttons.Arm.MouseButton1Click:Connect(function()
			showC4Menu(currentC4, false)
			remote:FireServer(currentC4.Object, "Arm", currentC4.Extras.ArmDurationClient or error("ArmDurationClient is nil"))
		end)

		buttons:FindFirstChild("Destroy").Activated:Connect(function()
			showC4Menu(currentC4, false)
			remote:FireServer(currentC4.Object, "Destroy")
		end)

		buttons.Take.Activated:Connect(function()
			showC4Menu(currentC4, false)
			remote:FireServer(currentC4.Object, "Take")
		end)

		buttons.Close.Activated:Connect(function()
			showC4Menu(currentC4, false)
		end)

		for _, v in ui.Object.Wires.Wires:GetChildren() do
			if v:IsA("TextButton") then
				v.Activated:Connect(function()
					showC4Menu(currentC4, false)
					remote:FireServer(currentC4.Object, "CutWire", tonumber(v.Name:sub(5, 5)))
				end)
			end
		end

		local sliderBar = getC4Menu().Object.Arm.Arm.SliderBar
		local function tryMoveSlider(input: InputObject): ()
			local inputType = input.UserInputType
			if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch and inputType ~= Enum.UserInputType.MouseMovement then
				return
			end

			if inputType == Enum.UserInputType.MouseMovement and sliderBar.GuiState ~= Enum.GuiState.Press then
				return
			end

			local percent = math.clamp(input.Position.X - sliderBar.AbsolutePosition.X, 0, sliderBar.AbsoluteSize.X) / sliderBar.AbsoluteSize.X
			setDuration(currentC4, percent)
		end

		setDuration(currentC4, 0)

		sliderBar.InputChanged:Connect(tryMoveSlider)
		sliderBar.InputBegan:Connect(tryMoveSlider)

		isFirstInit = false
	end

	ui:ToggleVisible(show)
end

local c4s: {[Instance]: C4} = {}
if RunService:IsClient() then
	local PlaySound = require(ReplicatedStorage.RoundRule.Common.PlaySound)

	local function forEachC4(c4: C4): ()
		local timerPart = c4.Object:FindFirstChild("TimerPart")
		if not timerPart then
			return
		end

		local surfaceGui = timerPart:FindFirstChild("Timer")
		if not surfaceGui then
			return
		end

		local timer = surfaceGui:FindFirstChild("TextLabel")
		if not timer or not timer:IsA("TextLabel") then
			return
		end

		local ui = getC4Menu()
		if currentC4 == c4 and ui.Visible then
			local distance = Players.LocalPlayer:DistanceFromCharacter(c4.Object.Position)
			if distance == 0 or distance > c4.Definition.InteractionRange then
				showC4Menu(c4, false)
			end
		end

		local explodeAt = c4.Object:GetAttribute("ExplodesAt") :: number?
		if explodeAt then
			local timeLeft = explodeAt - workspace:GetServerTimeNow()
			timer.Text = getTimerText(timeLeft)

			if currentC4 == c4 and ui.Visible then
				ui.Object.SidePanel.Timer.Text = getTimerText(timeLeft)
			end

			if not c4.Extras.BeganBeepingClient and timeLeft <= 5 then
				c4.Extras.BeganBeepingClient = true
				PlaySound(6992631696, nil, c4.Object, {
					Volume = 1.5,
					RollOffMinDistance = 10,
					RollOffMaxDistance = 40,
					PlaybackRegion = NumberRange.new(2.5, 7.5),
				})
			end
		else
			timer.Text = ""
		end
	end

	RunService.Heartbeat:Connect(function()
		local toRemove: {C4} = {}

		for _, c4 in c4s do
			if not c4.Object:IsDescendantOf(workspace) then
				table.insert(toRemove, c4)
				continue
			end

			forEachC4(c4)
		end

		for _, remove in toRemove do
			c4s[remove.Object] = nil
		end
	end)
end

local wires = {1, 2, 3, 4, 5, 6}

local explosionInfo: Types.ExplosionInfo = {
	Damage = 100,
	FalloffBegin = 40,
	FalloffEnd = 80,
	Pressure = 100000,
	VisualRadius = 10,

	IgnoreKarma = true,
	IgnoreSelfDefense = true,
}

if RunService:IsServer() then
	local ServerScriptService = game:GetService("ServerScriptService")
	local ExplosionParams = require(ReplicatedStorage.RoundRule.ExplosionParams)
	local Combat = require(ServerScriptService.Combat)

	local function pickAndRemove<T>(list: {T}): T
		assert(#list > 0, "List is empty")

		local index = math.random(#list)
		local item = list[index]

		table.remove(list, index)

		return item
	end

	local function isArmed(c4: C4): boolean
		return c4.Extras.ArmId ~= nil
	end

	local function disarm(c4: C4): ()
		c4.Extras.ArmId = nil
		c4.Extras.ArmedBy = nil
		c4.Extras.SafeWires = nil
		c4.Object:SetAttribute("ExplodesAt", nil)
	end

	local function destroy(c4: C4): ()
		disarm(c4)
		c4.Object:Destroy()
	end

	local function tryExplode(c4: C4, armId: any): ()
		local armedBy: Types.Participant? = c4.Extras.ArmedBy
		if not armedBy then
			return
		end

		if armId ~= c4.Extras.ArmId then
			return
		end

		destroy(c4)
		Combat.CreateExplosion(armedBy.Round, ExplosionParams.new(explosionInfo, c4.Object.Position, armedBy))
	end

	local function tryArm(c4: C4, participant: Types.Participant, duration: number?): ()
		if not duration then
			return
		end

		if isArmed(c4) then
			return
		end

		c4.Extras.ArmId = newproxy()
		c4.Extras.ArmedBy = participant
		c4.Extras.SafeWires = {}

		local wiresCopy = table.clone(wires)
		for i = 1, 5 do
			table.insert(c4.Extras.SafeWires, pickAndRemove(wiresCopy))
		end

		c4.Object:SetAttribute("ExplodesAt", workspace:GetServerTimeNow() + duration)
		task.delay(duration, tryExplode, c4, c4.Extras.ArmId)
	end

	local function tryDisarm(c4: C4, participant: Types.Participant, cutWire: number?): ()
		if not cutWire then
			return
		end

		if not isArmed(c4) then
			return
		end

		if participant == c4.Extras.ArmedBy or table.find(c4.Extras.SafeWires, cutWire) then
			return disarm(c4)
		end
		tryExplode(c4, c4.Extras.ArmId)
	end

	local function tryDestroy(c4: C4): ()
		if isArmed(c4) then
			return
		end

		destroy(c4)
	end

	local function tryTake(c4: C4, participant: Types.Participant): ()
		if isArmed(c4) then
			return
		end

		local c4Item = participant.Round:GetItemDefinition(c4.Definition.Name)
		if not c4Item then
			return warn("Could not find C4 item")
		end

		if c4Item.Slot and participant:IsItemSlotOccupied(c4Item.Slot) then
			return
		end

		participant:GiveItemFromItemDefinition(c4Item)
		destroy(c4)
	end

	remote.OnServerEvent:Connect(function(player: Player, instance: Instance, action: unknown, explodeAtOrWireCut: unknown): ()
		if typeof(action) ~= "string" or (typeof(explodeAtOrWireCut) ~= "number" and typeof(explodeAtOrWireCut) ~= "nil") then
			return
		end

		local c4 = c4s[instance]
		if not c4 then
			return
		end

		local round = assert(c4.Round, "C4 has no round")
		local participant = round:GetParticipant(player.Name)

		if not participant then
			return
		end

		if participant:GetStatus() ~= "Alive" then
			return
		end

		if player:DistanceFromCharacter(c4.Object.Position) > c4.Definition.InteractionRange * 1.1 then
			return
		end

		if action == "Arm" then
			tryArm(c4, participant, explodeAtOrWireCut)
		elseif action == "CutWire" then
			tryDisarm(c4, participant, explodeAtOrWireCut)
		elseif action == "Take" then
			tryTake(c4, participant)
		elseif action == "Destroy" then
			tryDestroy(c4)
		end
	end)
end

local interactable: Types.InteractableDefinition = {
	Name = "C4",

	Model = ReplicatedStorage.InteractableModels.C4,

	IsContinuousInteraction = false,
	InteractionRange = 7.5,

	OnInteractClient = function(object: C4): ()
		showC4Menu(object, true)
	end,

	OnLoadClient = function(object: C4): ()
		c4s[object.Object] = object
	end,

	OnLoadServer = function(object: C4): ()
		c4s[object.Object] = object
		object.Object.AncestryChanged:Connect(function()
			if not object.Object:IsDescendantOf(workspace) then
				c4s[object.Object] = nil
			end
		end)
	end,
}

return interactable