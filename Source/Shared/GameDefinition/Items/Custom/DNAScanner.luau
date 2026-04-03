local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local CreateRadarPoint = require(ReplicatedStorage.API.CreateRadarPoint)
local DNATraces = require(ReplicatedStorage.API.DNATraces)
local GameHooks = require(ReplicatedStorage.API.GameHooks)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local Decoy = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Decoy)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local UIAnimation = require(ReplicatedStorage.Shared.Interface.UILib.UIAnimation)

local module = {}

local ITEM_SLOT = 9

local MAX_SCAN_RANGE = 7.5

local CHARGE_DEPLETION_PER_STUD = 0.5
local MIN_CHARGE_DEPLETION = 5

local RECHARGE_RATE = 5
local currentCharge = 100

local clientAvailableTraces: {SampledTrace} = {}
local clientCurrentTrace: SampledTrace?
local clientAutoScan = true

local remote: RemoteEvent
if RunService:IsServer() then
	remote = Instance.new("RemoteEvent")
	remote.Name = "DNARemote"
	remote.Parent = script
else
	local found = script:WaitForChild("DNARemote")
	assert(found:IsA("RemoteEvent"), "DNARemote must be a RemoteEvent")
	remote = found
end

local raycastParams = RaycastParams.new()
raycastParams.CollisionGroup = "WeaponHitTargets"
raycastParams.FilterDescendantsInstances = {workspace.Characters}
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
local function PrimaryFireServer(item: Types.Item, origin: Vector3, direction: Vector3, participant: Types.Participant): ()
	local result = workspace:Raycast(origin, direction * MAX_SCAN_RANGE * 1.1)
	if not result then
		return
	end

	local round = participant.Round

	local object: DNATraces.IHasDNATraces?

	local hitPart = result.Instance :: BasePart

	if hitPart:IsDescendantOf(workspace.Characters) then
		local model = hitPart:FindFirstAncestorOfClass("Model")
		if model then
			if model:GetAttribute("Unidentified") or not model:HasTag("Corpse") then
				return
			end

			object = round:GetParticipant(model.Name)
		end
	elseif hitPart:HasTag("Item") then
		local mapItem = round:GetItem(hitPart)
		if mapItem then
			object = mapItem
		end
	elseif hitPart:HasTag("Interactable") then
		local interactable = round:GetProp(hitPart)
		if interactable then
			object = interactable
		end
	end

	if not object or not object.Extras.DNATraces then
		return
	end

	local samples: {SampledTrace} = {}
	for _, trace in object.Extras.DNATraces do
		table.insert(samples, {
			Target = trace.Target,
			Icon = trace.Icon,
			Object = trace.Object,
		})
	end

	remote:FireClient(participant.Player, samples)
end

type SampledTrace = DNATraces.IHasTarget & DNATraces.IHasObject & {
	Icon: string,
}

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
		PlaySound(4578451106, nil, SoundService, {
			SoundGroup = SoundService.AllSounds :: SoundGroup,
		})
	end

	local ui = getUI()

	remote.OnClientEvent:Connect(function(traces: {SampledTrace}?)
		if not traces then
			return resetClient()
		end

		for i, trace in traces do
			if DNATraces.HasEquivalentTrace(clientAvailableTraces, trace) then
				continue
			end
			table.insert(clientAvailableTraces, trace)

			local newTrace = ui.Object.DefaultSample:Clone()
			newTrace.Image = trace.Icon
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
	PrimaryHint = "Scan DNA",
	PrimaryFireServer = PrimaryFireServer,

	OnEquipClient = OnEquipClient,
	OnUnequipClient = OnUnequipClient,
})

module.Item = item

return table.freeze(module)