local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local Health = {}

function Health.TriggerHeal(participant: Types.Participant): ()
	local hum = participant:GetHumanoid()
	if not hum then
		return
	end

	if hum.Health <= 0 then
		return
	end

	if participant.Extras.FramedHealId then
		return
	end

	local id = newproxy()
	participant.Extras.FramedHealId = id

	task.spawn(function()
		while hum.Parent and hum.Health > 0 and hum.Health < hum.MaxHealth and participant.Extras.FramedHealId == id do
			hum.Health = math.min(hum.Health + 1, hum.MaxHealth)
			participant.Extras.FramedLastHealth = hum.Health
			task.wait(0.05)
		end
		participant.Extras.FramedHealId = nil
	end)
end

function Health.InitHeal(participant: Types.Participant): ()
	local hum = participant:GetHumanoid()
	if not hum then
		return
	end

	participant.Extras.FramedLastHealth = hum.Health
	participant.Extras.FramedHealId = nil
	hum:GetPropertyChangedSignal("Health"):Connect(function()
		local health = hum.Health

		if health > participant.Extras.FramedLastHealth then
			participant.Extras.FramedLastHealth = health
			return
		end

		participant.Extras.FramedLastHealth = health

		if health <= 0 then
			return
		end

		participant.Extras.FramedHealId = nil

		local id = newproxy()
		participant.Extras.FramedHealId2 = id

		task.wait(if health < 20 then 6 else 5)
		if participant.Extras.FramedHealId2 ~= id then
			return
		end
		Health.TriggerHeal(participant)
	end)
end

return table.freeze(Health)