local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)

local MIN_ARM_DURATION = 45
local MAX_ARM_DURATION = 360

local WIRE_COUNT = 6

local TEXT_HIGHLIGHT_COLOUR = Color3.fromRGB(66, 135, 245)

local explosionInfo: Types.ExplosionInfo = {
	Damage = 100,
	FalloffBegin = 40,
	FalloffEnd = 80,
	Pressure = 100000,
	VisualRadius = 25,

	IgnoreKarma = true,
	IgnoreSelfDefense = true,
}

local reducedExplosionInfo: Types.ExplosionInfo = {
	Damage = 100,
	FalloffBegin = 20,
	FalloffEnd = 50,
	Pressure = 500000,
	VisualRadius = 20,

	IgnoreKarma = true,
	IgnoreSelfDefense = true,
}

type C4 = Types.Interactable & {
	Extras: {
		ArmId: never?,
		ArmedBy: Types.Participant?,
		DangerousWires: {number}?,
		ArmDurationClient: number?,
		BeganBeepingClient: boolean?,
		[any]: never,
	},
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

local function getDangerousWireCountForDuration(duration: number): number
	local percent = (duration - MIN_ARM_DURATION) / (MAX_ARM_DURATION - MIN_ARM_DURATION) + 1 / WIRE_COUNT
	return math.clamp(math.floor(WIRE_COUNT * percent), 1, WIRE_COUNT - 1)
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
	local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
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

	local dangerousCount = getDangerousWireCountForDuration(duration)
	ui.Object.Arm.Arm.DangerousWires.Text = `{dangerousCount} wire{if dangerousCount ~= 1 then "s" else ""} will be deadly`

	c4.Extras.ArmDurationClient = duration
end

local function playBeep(): ()
	PlaySound(9117060347, nil, SoundService)
end

local isFirstInit = true
local function showC4Menu(c4: C4, show: boolean): ()
	currentC4 = c4
	assert(currentC4)

	local WalkSpeed = require(ReplicatedStorage.Shared.Character.WalkSpeed)
	local JumpPower = require(ReplicatedStorage.Shared.Character.JumpPower)

	local ui = getC4Menu()
	local buttons = ui.Object.SidePanel.Buttons

	if show then
		ui.Object.Wires.Visible = isArmedClient(c4)
		ui.Object.Arm.Visible = not isArmedClient(c4)

		for _, v in ui.Object.Wires.Wires:GetChildren() do
			if not v:IsA("TextButton") then
				continue
			end

			local uiGradient = assert(v:FindFirstChildOfClass("UIGradient"))
			uiGradient.Transparency = NumberSequence.new(0)
		end
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
			playBeep()
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
					local gradient = assert(v:FindFirstChildOfClass("UIGradient"))
					gradient.Transparency = NumberSequence.new(0.9)

					showC4Menu(currentC4, false)
					remote:FireServer(currentC4.Object, "CutWire", tonumber(v.Name:sub(5, 5)))
					PlaySound(9118822196, nil, SoundService, {
						Volume = 1.5,
						PlaybackRegion = NumberRange.new(0.11, 60000),
					})
					playBeep()
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

local c4s = DynamicValue.new({} :: {[Instance]: C4})
if RunService:IsClient() then
	local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)
	
	local isBadGuy = false

	local function updateMarkerVisibility(): ()
		for _, c4 in c4s() do
			local marker = c4.Object:FindFirstChild("Marker")
			if marker and marker:IsA("BillboardGui") then
				marker.Enabled = isBadGuy and isArmedClient(c4)
			end
		end
	end

	c4s:Connect(updateMarkerVisibility)

	local function playAboutToExplodeBeeps(c4: C4): ()
		local part = CreateEmptyPart(c4.Object.CFrame)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = c4.Object
		weld.Part1 = part
		part.Name = "SoundPart"
		part.Parent = c4.Object

		c4.Extras.BeganBeepingClient = true
		PlaySound(6992631696, nil, part, {
			Volume = 1.5,
			RollOffMinDistance = 10,
			RollOffMaxDistance = 40,
			PlaybackRegion = NumberRange.new(2.5, 7.5),
		})
	end

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
				playAboutToExplodeBeeps(c4)
			end
		else
			timer.Text = ""

			local soundPart = c4.Object:FindFirstChild("SoundPart")
			if soundPart then
				soundPart:Destroy()
			end

			c4.Extras.BeganBeepingClient = false
		end

		if isBadGuy then
			local distance = Players.LocalPlayer:DistanceFromCharacter(c4.Object.Position)
			if distance == 0 then
				distance = (workspace.CurrentCamera.CFrame.Position - c4.Object.Position).Magnitude
			end

			local marker = c4.Object:FindFirstChild("Marker")
			if not marker or not marker:IsA("BillboardGui") then
				return
			end

			local border = marker:FindFirstChild("Border")
			if not border or not border:IsA("ImageLabel") then
				return
			end

			local distanceLabel = marker:FindFirstChild("Distance")
			if not distanceLabel or not distanceLabel:IsA("TextLabel") then
				return
			end

			local colour: Color3
			if distance > explosionInfo.FalloffEnd then
				colour = Color3.new(0, 1, 0)
			elseif distance > explosionInfo.FalloffBegin then
				colour = Color3.new(1, 1, 0)
			else
				colour = Color3.new(1, 0, 0)
			end

			border.ImageColor3 = colour
			distanceLabel.TextColor3 = colour

			distanceLabel.Text = tostring(math.round(distance))
		end
	end

	RunService.Heartbeat:Connect(function()
		local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)

		local role = LocalParticipantInfo.GetParticipant().Role()
		isBadGuy = role.Definition.IsBadGuys or false

		local toRemove: {C4} = {}

		for _, c4 in c4s() do
			if not c4.Object:IsDescendantOf(workspace) then
				table.insert(toRemove, c4)
				continue
			end

			forEachC4(c4)
		end

		for _, remove in toRemove do
			c4s()[remove.Object] = nil
		end
		c4s:Invoke()
	end)
end

local wires = {1, 2, 3, 4, 5, 6}

local function highlightText(text: string): string
	return `<font color='#{TEXT_HIGHLIGHT_COLOUR:ToHex()}'>{text}</font>`
end

if RunService:IsServer() then
	local ServerScriptService = game:GetService("ServerScriptService")
	local DNAScanner = require(ReplicatedStorage.Shared.GameDefinition.Items.DNAScanner)
	local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)
	local Combat = require(ServerScriptService.Combat.Combat)

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
		c4.Extras.DangerousWires = nil
		c4.Object:SetAttribute("ExplodesAt", nil)
	end

	local function destroy(c4: C4): ()
		disarm(c4)
		c4.Object:Destroy()
	end

	local function tryExplode(c4: C4, armId: any, reducedPower: boolean?): ()
		local armedBy: Types.Participant? = c4.Extras.ArmedBy
		if not armedBy then
			return
		end

		if armId ~= c4.Extras.ArmId then
			return
		end

		if not c4.Object:IsDescendantOf(workspace) then
			return
		end
		
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://252142019"
		sound.Volume = 1
		sound.RollOffMinDistance = if reducedPower then 35 else 70
		sound.RollOffMaxDistance = if reducedPower then 70 else 240

		destroy(c4)
		Combat.CreateExplosion(armedBy.Round, ExplosionParams.new(if reducedPower then reducedExplosionInfo else explosionInfo, c4.Object.Position, armedBy), nil, sound)
	end

	local function tryArm(c4: C4, participant: Types.Participant, duration: number?): ()
		if not duration or duration < MIN_ARM_DURATION or duration > MAX_ARM_DURATION then
			return
		end

		if isArmed(c4) then
			return
		end

		local role = participant:GetRole()
		if not role.Definition.IsBadGuys then
			participant:SetFreeKill("armed a C4")
		end

		c4.Extras.ArmId = newproxy()
		c4.Extras.ArmedBy = participant
		c4.Extras.DangerousWires = {}

		local wiresCopy = table.clone(wires)
		for i = 1, getDangerousWireCountForDuration(duration) do
			table.insert(c4.Extras.DangerousWires, pickAndRemove(wiresCopy))
		end

		local safeWire = wiresCopy[1]

		participant:AddCorpseIcon({
			Name = "C4Defusal",
			Icon = "rbxassetid://17229908151",
			Description = `You find a note on their corpse saying that {highlightText("wire " .. safeWire)} will defuse a C4.`,
		})

		DNAScanner.RemoveDNATraces(c4)
		DNAScanner.AddDNATrace(c4, participant, nil, "rbxassetid://17229908151", c4.Object)

		c4.Object:SetAttribute("ExplodesAt", workspace:GetServerTimeNow() + duration)
		task.delay(duration, tryExplode, c4, c4.Extras.ArmId)
	end

	local function tryDisarm(c4: C4, participant: Types.Participant, cutWire: number?): ()
		if not cutWire or cutWire < 1 or cutWire > WIRE_COUNT then
			return
		end

		if not isArmed(c4) then
			return
		end

		local alwaysDisarm = false

		local defuserRole = participant:GetRole()
		if (c4.Extras.ArmedBy == participant) or (defuserRole.Definition.IsBadGuys) then
			alwaysDisarm = true
		end

		if alwaysDisarm or not table.find(c4.Extras.DangerousWires, cutWire) then
			return disarm(c4)
		end
		
		tryExplode(c4, c4.Extras.ArmId, true)
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

		local c4 = c4s()[instance]
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

	Model = ReplicatedStorage.Assets.InteractableModels.C4,

	IsContinuousInteraction = false,
	InteractionRange = 7.5,

	OnInteractClient = function(object: C4): ()
		showC4Menu(object, true)
	end,

	OnLoadClient = function(object: C4): ()
		c4s()[object.Object] = object
		c4s:Invoke()
	end,

	OnLoadServer = function(object: C4): ()
		c4s()[object.Object] = object
		c4s:Invoke()

		object.Object.AncestryChanged:Connect(function()
			if not object.Object:IsDescendantOf(workspace) then
				c4s()[object.Object] = nil
				c4s:Invoke()
			end
		end)
	end,
}

return interactable