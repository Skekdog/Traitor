local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Modify = require(ReplicatedStorage.API.Modify)
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)

local Propper = {}

local remote = GetRemote("ThirdPerson", script)

local function beforeHitProp(item: Types.Item, params: Types.DamageParams, prop: Types.Prop): boolean
	if prop.Interactable then
		return false
	end

	if GetPrimaryPart(prop.Model):IsGrounded() then
		return false
	end

	local participant = params.Attacker
	assert(participant)

	local character = participant:GetCharacter()
	assert(character)

	local root = character.PrimaryPart
	assert(root)

	character:ScaleTo(0.0001)
	ForEachPart(character, function(part)
		part.Transparency = 1
	end)

	local model = prop.Model:Clone()

	local part = GetPrimaryPart(model)
	part.CFrame = root.CFrame

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = model

	;(model :: Instance).Parent = character

	remote:FireClient(participant.Player, true)

	return false
end

if RunService:IsClient() then
	local Camera = require(ReplicatedStorage.API.Camera)
	remote.OnClientEvent:Connect(function(doThirdPerson: boolean): ()
		Camera.EnterAnimationView()
	end)
end

local Item = Modify(StandardGame.GetItem("Crowbar"), "Propper", {
	Description = "Become a prop",
	BeforeHitProp = beforeHitProp,

	AlternateFireClient = {__nil = true},
	AlternateFireServer = {__nil = true},
})

Propper.Item = Item

return Propper