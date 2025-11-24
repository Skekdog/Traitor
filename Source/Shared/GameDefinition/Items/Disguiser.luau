local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ShowAlert = require(ReplicatedStorage.Shared.Interface.Util.ShowAlert)
local Participant = require(ReplicatedStorage.Shared.RoundRule.Participant)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

local DISGUISED_SKIN_TONE = Color3.new(1, 1, 1)
local DISGUISED_SHIRT = 855773572
local DISGUISED_PANTS = 867838635

local DISGUISED_DESCRIPTION = Instance.new("HumanoidDescription")

DISGUISED_DESCRIPTION.HeadColor = DISGUISED_SKIN_TONE
DISGUISED_DESCRIPTION.LeftArmColor = DISGUISED_SKIN_TONE
DISGUISED_DESCRIPTION.RightArmColor = DISGUISED_SKIN_TONE
DISGUISED_DESCRIPTION.LeftLegColor = DISGUISED_SKIN_TONE
DISGUISED_DESCRIPTION.RightLegColor = DISGUISED_SKIN_TONE
DISGUISED_DESCRIPTION.TorsoColor = DISGUISED_SKIN_TONE

DISGUISED_DESCRIPTION.Shirt = DISGUISED_SHIRT
DISGUISED_DESCRIPTION.Pants = DISGUISED_PANTS

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

function module.DisguiseServer(participant: Types.Participant, enable: boolean, char: Model?, hum: Humanoid?, applyReset: boolean?): ()
	-- this is to prevent an error in studio when stopping the game.
	if not participant.Player.Parent then
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
			Participant.OnCharacterPartAdded(v)
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
			hum:ApplyDescriptionReset(DISGUISED_DESCRIPTION, Enum.AssetTypeVerification.Always)
		else
			hum:ApplyDescription(DISGUISED_DESCRIPTION, Enum.AssetTypeVerification.Always)
		end
	elseif foundDescription then
		if applyReset then
			hum:ApplyDescriptionReset(foundDescription, Enum.AssetTypeVerification.Always)
		else
			hum:ApplyDescription(foundDescription, Enum.AssetTypeVerification.Always)
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
			if v.Definition.Name == "Disguiser" then
				found = true
				break
			end
		end

		if not found then
			return
		end

		module.DisguiseServer(participant, enable)
	end)
end

local function OnEquipClient(item: Types.AnyItem): ()
	local CustomActions = require(ReplicatedStorage.API.CustomActions)
	CustomActions.Register("Disguise", function()
		clientDisguiseActive = not clientDisguiseActive
		ShowAlert("Disguise: " .. if clientDisguiseActive then "ON" else "OFF")
		remote:FireServer(clientDisguiseActive)
	end, 1)
end

local function OnEquipServer(item: Types.AnyItem, participant: Types.Participant): ()
	serverParticipantTable[participant.Player] = participant
end

local function OnUnequipClient(item: Types.AnyItem): ()
	local CustomActions = require(ReplicatedStorage.API.CustomActions)
	clientDisguiseActive = false
	CustomActions.Unregister("Disguise")
end

local function OnUnequipServer(item: Types.AnyItem, participant: Types.Participant): ()
	local data = serverParticipantTable[participant.Player]
	if not data then
		return
	end
	module.DisguiseServer(data, false)
	serverParticipantTable[participant.Player] = nil
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "Disguiser",
	Description = "When activated, conceals your identity and status from others.",
	Icon = "rbxassetid://107291373883291",

	CreditCost = 1,
	MaxStock = 1,

	OnEquipClient = OnEquipClient,
	OnEquipServer = OnEquipServer,

	OnUnequipClient = OnUnequipClient,
	OnUnequipServer = OnUnequipServer,
}

module.Item = item

return module