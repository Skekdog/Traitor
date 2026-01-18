local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local CreateRadarPoint = require(ReplicatedStorage.API.CreateRadarPoint)
local DamageSource = require(ReplicatedStorage.API.DamageSource)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local Participant = require(ReplicatedStorage.Shared.RoundRule.Participant)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local UIAnimation = require(ReplicatedStorage.Shared.Interface.UILib.UIAnimation)

local module = {}

local ITEM_SLOT = 9

local MAX_KILL_DISTANCE = 60
local MAX_KILL_TRACE_DURATION = 120

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

local function hasEquivalentTrace(t: {IHasTarget & IHasObject}, trace: IHasTarget & IHasObject): boolean
	for _, existingTrace in t do
		if existingTrace.Target == trace.Target and existingTrace.Object == trace.Object then
			return true
		end
	end
	return false
end

function module.AddDNATrace(object: IHasDNATraces, target: Types.Participant, duration: number?, icon: Content, instance: Instance): ()
	local traces = object.Extras.DNATraces or {}

	local trace: DNATrace = {
		ExpiresAt = if duration then workspace:GetServerTimeNow() + duration else nil,
		Target = target.Player.Name,
		Icon = icon.Uri or "",
		Object = instance,
	}

	if hasEquivalentTrace(traces, trace) then
		return
	end

	table.insert(traces, trace)

	object.Extras.DNATraces = traces
end

function module.RemoveDNATraces(object: IHasDNATraces): ()
	object.Extras.DNATraces = nil
end

function module.GetDNATraces(object: IHasDNATraces): {DNATrace}
	return object.Extras.DNATraces or {}
end

export type IHasDNATraces = {
	Extras: {
		DNATraces: {DNATrace}?,
		[any]: never,
	},
}

type IHasObject = {
	Object: Instance,
}

type IHasTarget = {
	Target: string
}

type SampledTrace = IHasTarget & IHasObject & {
	Icon: string,
}

type DNATrace = IHasTarget & IHasObject & {
	ExpiresAt: number?,
	Icon: string,
}

type Participant = Types.Participant & IHasDNATraces

local originalOnDeath = Participant.OnDeath
local function patchedOnDeath(participant: Participant, params: Types.DamageParams, deferVictoryCheck: boolean): ()
	remote:FireClient(participant.Player)

	local attacker = params.Attacker
	if not attacker then
		return
	end

	if (attacker:HasSelfDefenseAgainstParticipant(participant) and not participant:GetRole().Definition.CorpseHidesSelfDefense) or participant:IsFreeKill(attacker) then
		return
	end

	local char = participant:GetCharacter()
	if not char then
		return
	end

	local isEligible = DamageSource.IsFirearm(params.Source) or DamageSource.IsMelee(params.Source)
	if not isEligible then
		return
	end

	local distance = attacker.Player:DistanceFromCharacter(char:GetPivot().Position)
	if distance == 0 then
		return
	end

	local duration = math.lerp(MAX_KILL_TRACE_DURATION, 0, distance / MAX_KILL_DISTANCE)
	module.AddDNATrace(participant, attacker, duration, Content.fromAssetId(1043921089), char)

	participant:AddCorpseIcon({
		Name = "DNATrace",
		Icon = "rbxassetid://135886260297010",
		Description = "Traces of the killer's DNA are on the body. Use a DNA Scanner to track them.",
		DisplayText = `[TIMEUNTIL-{tostring(workspace:GetServerTimeNow() + duration)}]`,
	})
end

local originalDropItem = Participant.DropItem
local function patchedDropItem(participant: Types.Participant, item: Types.Item, throwDirection: Vector3?): ()
	if item.DropDisabled or not item.Model then
		return
	end
	module.AddDNATrace(item, participant, nil, item.IconContent or Content.fromAssetId(4795275417), item.Model)
end

Participant.DropItem = function(participant: Types.Participant, item: Types.Item, throwDirection: Vector3?): ()
	patchedDropItem(participant, item, throwDirection)
	originalDropItem(participant, item, throwDirection)
end

Participant.OnDeath = function(participant: Types.Participant, params: Types.DamageParams, deferVictoryCheck: boolean): ()
	patchedOnDeath(participant, params, deferVictoryCheck)
	originalOnDeath(participant, params, deferVictoryCheck)
end

local raycastParams = RaycastParams.new()
raycastParams.CollisionGroup = "WeaponHitTargets"
raycastParams.FilterDescendantsInstances = {workspace.Characters}
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
local function PrimaryFireServer(item: Types.Item, participant: Types.Participant, origin: Vector3, direction: Vector3): ()
	local result = workspace:Raycast(origin, direction * MAX_SCAN_RANGE * 1.1)
	if not result then
		return
	end

	local round = participant.Round

	local object: IHasDNATraces?

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
		local interactable = round:GetInteractable(hitPart)
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

		local targetCharacter = workspace.Characters:FindFirstChild(clientCurrentTrace.Target)
		if not targetCharacter or not targetCharacter:IsA("Model") then
			return
		end

		local cframe = targetCharacter:GetPivot()
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
			if hasEquivalentTrace(clientAvailableTraces, trace) then
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

local item = Custom({
	Name = "DNAScanner",
	DisplayName = "DNA Scanner",
	Description = "Collects DNA from objects of interest, revealing the location of whoever interacted with it.",
	IconContent = Content.none,

	ItemGroup = {
		PreferredSlot = 9,
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

return module