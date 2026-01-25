local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetParticipant = require(ReplicatedStorage.API.GetParticipant)
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Types = require(ReplicatedStorage.API.Types)

local remote = GetRemote("ItemFire")

local MAX_SHOOTER_DISTANCE = 15

local function validateItemUsage(participant: Types.Participant, item: Types.Item, action: "Primary" | "Alternate", origin: Vector3, direction: Vector3): string?
	if action == "Primary" and not item.PrimaryFireServer then
		return "NoPrimaryFire"
	elseif action == "Alternate" and not item.AlternateFireServer then
		return "NoAlternateFire"
	end

	if action == "Primary" and item.PrimaryDisabled then
		return "PrimaryFireDisabled"
	elseif action == "Alternate" and item.AlternateDisabled then
		return "AlternateFireDisabled"
	end

	if participant:GetHealth() <= 0 then
		return "NotAlive"
	end

	local char = participant:GetCharacter()
	if not char then
		return "OriginTooFar"
	end

	local head = char:WaitForChild("Head")
	if not head or not head:IsA("BasePart") or (head.Position - origin).Magnitude > MAX_SHOOTER_DISTANCE then
		return "OriginTooFar"
	end

	if item.PregameDisable and participant.Round:IsPreGame() then
		return "PregameDisabled"
	end

	return nil
end

local function fire(action: "Primary" | "Alternate", item: Types.Item, participant: Types.Participant, origin: Vector3, direction: Vector3, data: unknown): string | {string}?
	local char = assert(participant:GetCharacter())

	local sound = if action == "Primary" then item.PrimarySound else item.AlternateSound
	if sound then
		for _, v in Players:GetPlayers() do
			if v ~= participant.Player then
				PlaySound(sound, nil, char.PrimaryPart, nil, v)
			end
		end
	end

	if item.IsSingleUse then
		participant:RemoveItem(item)
	end

	if action == "Primary" then
		assert(item.PrimaryFireServer)
		return item.PrimaryFireServer(item, origin, direction, participant, data)
	else
		assert(item.AlternateFireServer)
		return item.AlternateFireServer(item, origin, direction, participant, data)
	end
end

remote.OnServerEvent:Connect(function(player, itemName: unknown, action: unknown, origin: unknown, direction: unknown, data: unknown): ()
	if typeof(itemName) ~= "string" then
		return remote:FireClient(player, "InvalidItemName")
	end

	if action ~= "Primary" and action ~= "Alternate" then
		return remote:FireClient(player, "InvalidAction")
	end

	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return remote:FireClient(player, "InvalidVectorTypes")
	end

	local participant = GetParticipant(player)
	if not participant then
		return remote:FireClient(player, "NotAlive")
	end

	local item = participant:GetEquippedItem()
	if not item or item.Name ~= itemName then
		return remote:FireClient(player, "NotEquipped")
	end

	local result: string | {string}? = validateItemUsage(participant, item, action, origin, direction)
	if result then
		return remote:FireClient(player, result)
	end

	result = fire(action, item, participant, origin, direction, data)
	if result and (typeof(result) == "string" or #result > 0) then
		return remote:FireClient(player, result)
	end
end)

return nil