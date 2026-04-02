local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.API.Types)

local function getPlayerFromAttribute(interactable: Types.Prop): Player?
	local name = interactable.Model:GetAttribute("Player") :: string?
	if not name then
		return nil
	end

	local player = Players:FindFirstChild(name)
	assert(not player or player:IsA("Player"), "Player is not a Player")

	return player
end

local function setAssociatedPlayerClient(interactable: Types.Prop, player: Player?): ()
	interactable.Extras.Player = player
end

local function ReplicateAssociatedPlayer(prop: Types.Prop): ()
	if RunService:IsServer() then
		local player: Player? = prop.Extras.Player
		if not player then
			return
		end

		prop.Model:SetAttribute("Player", player.Name)

		return
	end

	local player = getPlayerFromAttribute(prop)
	if not player then
		prop.Model:GetAttributeChangedSignal("Player"):Connect(function()
			setAssociatedPlayerClient(prop, getPlayerFromAttribute(prop))
		end)
	end

	setAssociatedPlayerClient(prop, player)
end

return ReplicateAssociatedPlayer