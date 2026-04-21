local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
local Infected = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.Infection.Roles.Infected)
local Survivor = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.Infection.Roles.Survivor)

local Highlights = {}

function Highlights.Kills(attacker: Types.Participant, victim: Types.Participant): ()
    if attacker == victim then
        return
    end

	local round = attacker.Round

	local attackerRole = attacker:GetRole().Definition
	local victimRole = victim:GetRole().Definition

	if attackerRole == Infected and victimRole == Survivor then
		if not round.Extras.AnyInfectionsHappened then
			attacker.Extras.InfectionsSpread = 1
			round.Extras.AnyInfectionsHappened = true
			round:AddHighlight({
				Title = "Patient Zero",
				Description = attacker:GetFormattedName() .. " brought about the first infection.",
				Priority = 1,
				Group = "First Blood",
			})

			return
		end

		attacker.Extras.InfectionsSpread = (attacker.Extras.InfectionsSpread or 0) + 1
		local count = attacker.Extras.InfectionsSpread

		if count == 1 then
			round:AddHighlight({
				Title = "Coughed On You",
				Description = attacker:GetFormattedName() .. " infected one person. I don't feel so good...",
				Priority = 1,
				Group = "Infections",
			})
		elseif count == 2 then
			round:AddHighlight({
				Title = "Sneezed Around",
				Description = attacker:GetFormattedName() .. " infected two people. Pleads \"my bad\".",
				Priority = 2,
				Group = "Infections",
			})
		elseif count == 3 then
			round:AddHighlight({
				Title = "Mask Off",
				Description = attacker:GetFormattedName() .. " took their mask off and stared in the general direction of three.",
				Priority = 3,
				Group = "Infections",
			})
		elseif count == 4 then
			round:AddHighlight({
				Title = "Plague-Bringer",
				Description = attacker:GetFormattedName() .. " yelled \"Plague upon thee!\" at four people.",
				Priority = 4,
				Group = "Infections",
			})
		elseif count >= 5 then
			round:AddHighlight({
				Title = "Super Spreader",
				Description = attacker:GetFormattedName() .. " sneezed on no less than five people.",
				Priority = count,
				Group = "Infections",
			})
		end
	elseif attackerRole == Survivor and victimRole == Infected then
		if not round.Extras.AnyInfectedKilled then
			round.Extras.AnyInfectedKilled = true
			attacker.Extras.InfectedKilled = 1
			round:AddHighlight({
				Title = "Curfew",
				Description = attacker:GetFormattedName() .. " killed the first infected.",
				Priority = 1,
				Group = "First Blood",
			})

			return
		end

		attacker.Extras.InfectedKilled = (attacker.Extras.InfectedKilled or 0) + 1
		local count = attacker.Extras.InfectedKilled

		if count == 1 then
			round:AddHighlight({
				Title = "The Knox Event Is Contained",
				Description = attacker:GetFormattedName() .. " stopped one infected.",
				Priority = 1,
				Group = "Infected Killed"
			})
		elseif count == 2 then
			round:AddHighlight({
				Title = "Don't Dead",
				Description = attacker:GetFormattedName() .. " opened the insides of two infected.",
				Priority = 2,
				Group = "Infected Killed",
			})
		elseif count == 3 then
			round:AddHighlight({
				Title = "Quarantined",
				Description = attacker:GetFormattedName() .. " sent three infected back home.",
				Priority = 3,
				Group = "Infected Killed",
			})
		elseif count >= 4 then
			round:AddHighlight({
				Title = "The Only Thing They Fear",
				Description = attacker:GetFormattedName() .. " sent at least four little devils away.",
				Priority = count,
				Group = "Infected Killed",
			})
		end
	end
end

return Highlights