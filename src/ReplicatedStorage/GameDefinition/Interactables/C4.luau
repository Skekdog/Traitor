local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.RoundRule.Types)

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

local c4s: {[Instance]: Types.Interactable} = {}
if RunService:IsClient() then
	local function forEachC4(c4: Types.Interactable): ()
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

		local explodeAt = c4.Object:GetAttribute("ExplodesAt") :: number?
		if explodeAt then
			local timeLeft = explodeAt - workspace:GetServerTimeNow()
			local minutes = math.floor(timeLeft / 60)
			local seconds = timeLeft % 60
			timer.Text = string.format("%02d:%02d", minutes, seconds)
		else
			timer.Text = ""
		end
	end

	RunService.Heartbeat:Connect(function()
		local toRemove: {Types.Interactable} = {}

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

	local function tryExplode(c4: Types.Interactable): ()
		local armedBy: Types.Participant? = c4.Extras.ArmedBy
		if not armedBy then
			return
		end

		if c4.Extras.ArmId ~= c4.Extras.ArmId then
			return
		end

		Combat.CreateExplosion(armedBy.Round, ExplosionParams.new(explosionInfo, c4.Object.Position, armedBy))
	end

	local function tryArm(c4: Types.Interactable, participant: Types.Participant, duration: number): ()
		local explodeAt = c4.Object:GetAttribute("ExplodesAt") :: number?
		if explodeAt then
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
		task.delay(duration, tryExplode, c4)
	end

	remote.OnServerEvent:Connect(function(player: Player, instance: Instance, action: unknown, explodeAtOrWireCut: unknown): ()
		if typeof(action) ~= "string" or typeof(explodeAtOrWireCut) ~= "number" then
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
			
		elseif action == "Take" then
			
		elseif action == "Destroy" then
			
		end
	end)
end

local interactable: Types.InteractableDefinition = {
	Name = "C4",

	Model = ReplicatedStorage.InteractableModels.C4,

	IsContinuousInteraction = false,
	InteractionRange = 7.5,

	OnInteractClient = function(object: Types.Interactable): ()
		if object.Object:GetAttribute("ExplodesAt") then
			return
		end

		remote:FireServer(object.Object, "Arm", 10)
	end,

	OnLoadClient = function(object: Types.Interactable): ()
		c4s[object.Object] = object
	end,

	OnLoadServer = function(object: Types.Interactable): ()
		c4s[object.Object] = object
		object.Object.AncestryChanged:Connect(function()
			if not object.Object:IsDescendantOf(workspace) then
				c4s[object.Object] = nil
			end
		end)
	end,
}

return interactable