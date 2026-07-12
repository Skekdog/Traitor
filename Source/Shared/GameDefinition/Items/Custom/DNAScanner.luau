local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Audio = require(ReplicatedStorage.API.Audio)
local CreateRadarPoint = require(ReplicatedStorage.API.CreateRadarPoint)
local DNATraces = require(ReplicatedStorage.API.DNATraces)
local GameHooks = require(ReplicatedStorage.API.GameHooks)
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local Message = require(ReplicatedStorage.API.Interface.Message)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local Decoy = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Decoy)
local Types = require(ReplicatedStorage.API.Types)
local Plural = require(ReplicatedStorage.Shared.Grammar.Plural)
local UIAnimation = require(ReplicatedStorage.Shared.Interface.UILib.UIAnimation)
local GetRemote = require(ReplicatedStorage.API.GetRemote)

local module = {}

local ITEM_SLOT = 9

local MAX_SCAN_RANGE = 7.5

local CHARGE_DEPLETION_PER_STUD = 0.5
local MIN_CHARGE_DEPLETION = 5

local RECHARGE_RATE = 5
local currentCharge = 100

local BEEP_SOUND = Audio.MakeSound({
	Content = Content.fromAssetId(4578451106),
})

local clientAvailableTraces: {DNATraces.DNATrace} = {}
local clientCurrentTrace: DNATraces.DNATrace?
local clientAutoScan = true

local remote = GetRemote("DNA", script)

local function PrimaryFireClient(item: Types.Item, origin: Vector3, direction: Vector3)
	local Raycasts = require(ReplicatedStorage.API.Item.Behaviour.Raycasts)
	local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)

	local char = LocalCharacter.Character()
	if not char then
		return false
	end

	local result = Raycasts.Hitscan(Raycasts.GetDefaultRaycastParams(char), origin, direction, MAX_SCAN_RANGE)
	if not result.Hit then
		return false
	end

	local mapObject = GetMapObject(result.Hit.Part, {"Corpse", "Item", "Interactable"})
	if not mapObject then
		return false
	end

	item:SetServerData("Primary", {Part = result.Hit.Part, Position = result.Position})

	return true
end

local function PrimaryFireServer(item: Types.Item, origin: Vector3, direction: Vector3, participant: Types.Participant, data: any): ()
	local GetParticipant = require(ReplicatedStorage.API.GetParticipant)
	local Checks = require(ReplicatedStorage.API.Item.Behaviour.Checks)

	if typeof(data) ~= "table" then
		return "InvalidRequest"
	end

	local position = data.Position
	if typeof(position) ~= "Vector3" then
		return "InvalidRequest"
	end

	local part = data.Part
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") then
		return "InvalidRequest"
	end

	if not Checks.TargetDistance(item, origin, position, part) then
		return "TargetTooFar"
	end

	local round = participant.Round

	if not Checks.RaycastStatic(round:GetMap(), origin, position, part) then
		return "StaticObscured"
	end

	local object: DNATraces.HasDNATraces?

	local model = GetMapObject(part, {"Corpse", "Item", "Interactable"})
	if not model then
		return "InvalidObject"
	end

	if model:HasTag("Corpse") then
		local foundParticipant = GetParticipant(model)
		object = foundParticipant

		if foundParticipant and foundParticipant.Corpse then
			foundParticipant.Corpse:SearchAsAlive(participant, false)
		end
	elseif model:HasTag("Item") then
		local mapItem = round:GetItem(model)
		if mapItem then
			object = mapItem
		end
	elseif model:HasTag("Interactable") then
		local interactable = round:GetProp(model)
		if interactable then
			object = interactable
		end
	end

	if not object then
		return "NoObject"
	end

	Audio.Play2D(ReplicatedStorage.Assets.ItemSounds.DNAScanner, nil, nil, participant.Player)

	if not object.Extras.DNATraces then
		Message.Popup("No DNA traces found.", participant.Player)
		return
	end

	local samples: {DNATraces.DNATrace} = {}
	for _, trace in object.Extras.DNATraces do
		if (trace.ExpiresAt or math.huge) > workspace:GetServerTimeNow() then
			table.insert(samples, {
				Target = trace.Target,
				Icon = trace.Icon,
				Object = trace.Object,
			})
		end
	end

	if #samples == 0 and #object.Extras.DNATraces > 0 then
		Message.Popup("The DNA traces have decayed.")
		return
	end

	remote:FireClient(participant.Player, samples)
end

local function getUI()
	local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
	local ui = UIManager.WaitForUI("DNAScanner") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.DNAScanner)}
	return ui
end

if RunService:IsClient() then
	local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)

	local function resetClient(): ()
		clientAvailableTraces = {}
		clientCurrentTrace = nil
		currentCharge = 100

		local ui = getUI()
		for _, v in ui.Object.Samples:GetChildren() do
			if v:IsA("ImageButton") then
				v:Destroy()
			end
		end
	end

	local function tryScan(): ()
		local item = ClientInventory.Inventory.Slots()[ITEM_SLOT]
		if not item or item.Name ~= "DNAScanner" then
			return
		end

		if not clientCurrentTrace or currentCharge < 100 then
			return
		end

		local targetPlayer = Players:FindFirstChild(clientCurrentTrace.Target)
		if not targetPlayer or not targetPlayer:IsA("Player") then
			return
		end

		local cframe = Decoy.GetPlayerPosition(targetPlayer)
		if not cframe then
			local targetCharacter = workspace.Characters:FindFirstChild(clientCurrentTrace.Target)
			if not targetCharacter or not targetCharacter:IsA("Model") then
				return
			end
			cframe = targetCharacter:GetPivot()
		end
		assert(cframe)

		local distance = Players.LocalPlayer:DistanceFromCharacter(cframe.Position)
		if distance == 0 then
			return
		end

		local deplete = math.max(MIN_CHARGE_DEPLETION, CHARGE_DEPLETION_PER_STUD * distance)
		currentCharge = math.max(currentCharge - deplete, 0)

		local old = workspace.RadarPoints:FindFirstChild("DNATrace")
		if old then
			old:Destroy()
		end

		CreateRadarPoint(cframe, Color3.fromRGB(0, 110, 255), "DNATrace")
		Audio.Play2D(BEEP_SOUND)
	end

	local ui = getUI()

	remote.OnClientEvent:Connect(function(traces: {DNATraces.DNATrace}?)
		if not traces then
			return resetClient()
		end

		Message.Popup(Plural(#traces, "Trace", "Traces") .. " acquired.")

		for i, trace in traces do
			if DNATraces.HasEquivalentTrace(clientAvailableTraces, trace) then
				continue
			end
			table.insert(clientAvailableTraces, trace)

			local newTrace = ui.Object.DefaultSample:Clone()
			newTrace.ImageContent = trace.Icon
			newTrace.Visible = true
			newTrace.UIStroke.Enabled = false
			newTrace.Name = tostring(trace)
			newTrace.Activated:Connect(function()
				if clientCurrentTrace == trace then
					return
				end
				clientCurrentTrace = trace

				for _, v in ui.Object.Samples:GetChildren() do
					if v:IsA("ImageButton") then
						local uiStroke = v:FindFirstChildOfClass("UIStroke") or error("no ui stroke")
						uiStroke.Enabled = v == newTrace
					end
				end
			end)
			newTrace.Parent = ui.Object.Samples :: any
		end

		if not clientCurrentTrace then
			clientCurrentTrace = traces[1]
			local button = ui.Object.Samples:FindFirstChild(tostring(clientCurrentTrace)) or error("no button");
			(button:FindFirstChildOfClass("UIStroke") or error("no ui stroke")).Enabled = true

			if clientAutoScan then
				tryScan()
			end
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		local lastCharge = currentCharge
		currentCharge = math.min(currentCharge + RECHARGE_RATE * dt, 100)

		if currentCharge == lastCharge then
			return
		end

		if clientAutoScan then
			tryScan()
		end

		UIAnimation.Slider(ui.Object.DNAChargeBar.Background, nil, currentCharge, 100)
		ui.Object.DNAChargeBar.ChargeLabel.Text = string.format("%.1f%%", currentCharge)
	end)

	ui.Object.ScanButton.Activated:Connect(tryScan)

	ui.Object.AutoScanButton.Activated:Connect(function()
		clientAutoScan = not clientAutoScan
		UIAnimation.TransitionSwitch(ui.Object.AutoScanButton.Value, clientAutoScan)
		if clientAutoScan then
			tryScan()
		end
	end)

	UIAnimation.TransitionSwitch(getUI().Object.AutoScanButton.Value, clientAutoScan)
end

local function OnEquipClient(): ()
	local ui = getUI()
	ui:ToggleVisible(true)
end

local function OnUnequipClient(): ()
	local ui = getUI()
	ui:ToggleVisible(false)
end

GameHooks.OnDeath["DNAScanner"] = function(round, participant): ()
	remote:FireClient(participant.Player)
end

local item = Custom({
	Name = "DNAScanner",
	DisplayName = "DNA Scanner",
	Description = "Collects DNA from objects of interest, revealing the location of whoever interacted with it.",
	IconContent = Content.none,

	ItemGroup = {
		PreferredSlot = ITEM_SLOT,
	},

	Model = ReplicatedStorage.Assets.ItemModels.DNAScanner,
	HoldAnimation = Content.fromAssetId(134193046304179),

	PrimaryToggled = true,
	PrimaryHint = "Collect DNA",
	PrimaryFireServer = PrimaryFireServer,
	PrimaryFireClient = PrimaryFireClient,

	MaxDistance = MAX_SCAN_RANGE,

	OnEquipClient = OnEquipClient,
	OnUnequipClient = OnUnequipClient,
})

module.Item = item

return table.freeze(module)