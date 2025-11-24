local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Fire = require(ReplicatedStorage.API.Fire)
local GetParticipant = require(ReplicatedStorage.API.GetParticipant)
local GetRound = require(ReplicatedStorage.API.GetRound)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Types = require(ReplicatedStorage.API.Types)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)

local BURN_INTERVAL = 0.1

local burningObjects: {Types.MapObject} = {}

CollectionService:GetInstanceAddedSignal("Burning"):Connect(function(instance)
	if instance:IsA("BasePart") or instance:IsA("Model") then
		table.insert(burningObjects, instance)
	end
end)

CollectionService:GetInstanceRemovedSignal("Burning"):Connect(function(instance)
	local index = table.find(burningObjects, instance :: any)
	if index then
		table.remove(burningObjects, index)
	end
end)

local cumulativeDt = 0
RunService.Heartbeat:Connect(function(dt)
	cumulativeDt += dt
	if cumulativeDt < BURN_INTERVAL then
		return
	end

	cumulativeDt = 0

	local round = GetRound()

	for _, object in burningObjects do
		local burnedParticipants: {Types.Participant} = {}
		ForEachPart(object, function(part)
			for _, v in workspace:GetPartsInPart(part) do
				local model = v:FindFirstAncestorOfClass("Model")
				if not model then
					continue
				end

				local participant = GetParticipant(model.Name)
				if not participant or not participant:IsAlive() then
					continue
				end

				if table.find(burnedParticipants, participant) then
					continue
				end

				table.insert(burnedParticipants, participant)

				participant:TryTakeDamage({
					Amount = 1,
					Source = "Burn",
					Attacker = Fire.Attackers[object],
				})

				PlaySound(ReplicatedStorage.Assets.WeaponSounds.FlareBurn, nil, v)
			end
		end)

		local prop = round:GetProp(object)
		if prop then
			prop:TryTakeDamage({
				Amount = 1,
				Source = "Burn",
				Attacker = Fire.Attackers[object]
			})
		end
	end
end)

return nil