local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Message = require(ReplicatedStorage.API.Interface.Message)
local Types = require(ReplicatedStorage.API.Types)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)

local module = {}

local DISGUISED_DESCRIPTION = ReplicatedStorage.Shared.RoundRule.Assets.TestDummy.Humanoid.HumanoidDescription

local serverParticipantTable: {[Player]: Types.Participant?} = {}

local remote: RemoteEvent
if RunService:IsServer() then
	remote = Instance.new("RemoteEvent")
	remote.Name = "Disguise"
	remote.Parent = script
else
	local found = script:WaitForChild("Disguise")
	assert(found:IsA("RemoteEvent"), "Disguise must be a RemoteEvent")
	remote = found
end

local clientDisguiseActive = false

function module.DisguiseServer(source: string, participant: Types.Participant, enable: boolean, char: Model?, hum: Humanoid?, applyReset: boolean?): ()
	-- this is to prevent an error in studio when stopping the game.
	if not participant.Player.Parent then
		return
	end

	local activeSources: {string} = participant.Extras.DisguiseSources or {}
	participant.Extras.DisguiseSources = activeSources

	if enable then
		if not table.find(activeSources, source) then
			table.insert(activeSources, source)
		end
	else
		local index = table.find(activeSources, source)
		if index then
			table.remove(activeSources, index)
		end
	end

	if enable and #activeSources > 1 then
		return
	elseif not enable and #activeSources > 0 then
		return
	end

	hum = hum or participant:GetHumanoid()
	if not hum then
		return
	end

	char = char or participant:GetCharacter()
	if not char then
		return
	end

	if char:GetAttribute("IsDisguised") == enable then
		return
	end
	char:SetAttribute("IsDisguised", enable)

	hum.ApplyDescriptionFinished:Once(function()
		local item = char:FindFirstChild("Item")
		if item then
			local motor = item:FindFirstChildOfClass("Motor6D")
			if motor then
				local hand = char:FindFirstChild("RightHand")
				if hand and hand:IsA("BasePart") then
					motor.Part0 = hand
				end
			end
		end

		for _, v in char:GetDescendants() do
			participant:OnCharacterInstanceAdded(v)
		end
	end)

	local partData: {[BasePart]: {Material: Enum.Material, Color: Color3}} = {}
	for _, part in char:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end

		partData[part] = {Material = part.Material, Color = part.Color}
	end

	local foundDescription = char:FindFirstChild("DisguiserHumanoidDescription")
	assert(not foundDescription or foundDescription:IsA("HumanoidDescription"), "DisguiserHumanoidDescription must be a HumanoidDescription")

	if enable then
		if not foundDescription then
			-- We only set it once. This is because if a player spams the disguiser, they will end up with the description just being the disguise description. Bad!
			local new = hum:GetAppliedDescription()
			new.Name = "DisguiserHumanoidDescription"
			new.Parent = char
		end
		if applyReset then
			hum:ApplyDescriptionResetAsync(DISGUISED_DESCRIPTION, Enum.AssetTypeVerification.Always)
		else
			hum:ApplyDescriptionAsync(DISGUISED_DESCRIPTION, Enum.AssetTypeVerification.Always)
		end
	elseif foundDescription then
		if applyReset then
			hum:ApplyDescriptionResetAsync(foundDescription, Enum.AssetTypeVerification.Always)
		else
			hum:ApplyDescriptionAsync(foundDescription, Enum.AssetTypeVerification.Always)
		end
	end

	if char:GetAttribute("RemoveClothing") then
		local shirt = char:FindFirstChildOfClass("Shirt")
		if shirt then
			shirt:Destroy()
		end

		local pants = char:FindFirstChildOfClass("Pants")
		if pants then
			pants:Destroy()
		end

		local tshirt: ShirtGraphic?
		repeat
			tshirt = char:FindFirstChildOfClass("ShirtGraphic")
			if tshirt then
				tshirt:Destroy()
			end
		until not tshirt
	end

	if char:GetAttribute("PreservePartAppearance") then
		for part, data in partData do
			local newPart = char:FindFirstChild(part.Name)
			if not newPart or not newPart:IsA("BasePart") then
				continue
			end
			newPart.Material = data.Material
			newPart.Color = data.Color
		end
	end
end

if RunService:IsServer() then
	remote.OnServerEvent:Connect(function(player, enable: unknown)
		if typeof(enable) ~= "boolean" then
			return
		end

		local participant = serverParticipantTable[player]
		if not participant then
			return
		end

		local found = false
		for _, v in participant:GetItems() do
			assert(v)
			if v.Name == "Disguiser" then
				found = true
				break
			end
		end

		if not found then
			return
		end

		module.DisguiseServer("Disguiser", participant, enable)
	end)
end

local function OnEquipClient(item: Types.Item): ()
	local CustomActions = require(ReplicatedStorage.API.CustomActions)
	CustomActions.Register("Disguise", function()
		clientDisguiseActive = not clientDisguiseActive
		Message.Popup("Disguise: " .. if clientDisguiseActive then "ON" else "OFF")
		remote:FireServer(clientDisguiseActive)
	end, 1)
end

local function OnEquipServer(item: Types.Item, participant: Types.Participant): ()
	serverParticipantTable[participant.Player] = participant
end

local function OnUnequipClient(item: Types.Item): ()
	local CustomActions = require(ReplicatedStorage.API.CustomActions)
	clientDisguiseActive = false
	CustomActions.Unregister("Disguise")
end

local function OnUnequipServer(item: Types.Item, participant: Types.Participant): ()
	local data = serverParticipantTable[participant.Player]
	if not data then
		return
	end
	module.DisguiseServer("Disguiser", data, false)
	serverParticipantTable[participant.Player] = nil
end

local item = Custom({
	Name = "Disguiser",
	Description = "When activated, conceals your identity and status from others.",
	IconContent = Content.fromAssetId(107291373883291),

	CorpseIconDescription = "They were using %s.",

	Cost = 1,
	MaxStock = 1,

	OnEquipClient = OnEquipClient,
	OnEquipServer = OnEquipServer,

	OnUnequipClient = OnUnequipClient,
	OnUnequipServer = OnUnequipServer,
})

module.Item = item

return table.freeze(module)