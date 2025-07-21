local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local ShowAlert = require(ReplicatedStorage.Shared.Interface.Util.ShowAlert)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

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

local function disguiseServer(participant: Types.Participant, enable: boolean?): ()
	participant.Player:SetAttribute("IsDisguised", if enable == nil then not participant.Player:GetAttribute("IsDisguised") else enable)
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

		disguiseServer(participant, enable)
	end)
end

local function OnEquipClient(item: Types.Item): ()
	ControlManager.Register("Disguise", function(_, state)
		clientDisguiseActive = not clientDisguiseActive
		ShowAlert("Disguise: " .. if clientDisguiseActive then "ON" else "OFF")
		remote:FireServer(clientDisguiseActive)

		return Enum.ContextActionResult.Sink
	end, nil, {
		Toggled = true,
		Keybind = {
			ConsoleKeybind = Enum.KeyCode.ButtonR1,
			KBMKeybind = Enum.KeyCode.Semicolon,
		}
	})
end

local function OnEquipServer(item: Types.Item, participant: Types.Participant): ()
	serverParticipantTable[participant.Player] = participant
end

local function OnUnequipClient(item: Types.Item): ()
	clientDisguiseActive = false
	ControlManager.Unregister("Disguise")
end

local function OnUnequipServer(item: Types.Item, participant: Types.Participant): ()
	disguiseServer(participant, false)
	serverParticipantTable[participant.Player] = nil
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "Disguiser",
	Description = "Conceals your identity from others. Use semicolon to activate.",
	Icon = "rbxassetid://7677183404",

	CreditCost = 1,
	MaxStock = 1,

	OnEquipClient = OnEquipClient,
	OnEquipServer = OnEquipServer,

	OnUnequipClient = OnUnequipClient,
	OnUnequipServer = OnUnequipServer,
}

module.Item = item

return module