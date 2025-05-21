local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DNAScanner = require(script.Parent.DNAScanner)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local THROW_FORCE = 80
local DAMAGE = 100

local function throw(item: Types.MeleeWeapon, _, origin: Vector3, direction: Vector3, attacker: Types.Participant): ()
	local model = item.Model:Clone()

	local map = attacker.Round:GetMap()
	local didThrow = attacker:TryThrowAssembly(model, THROW_FORCE, map.ItemSpawns, origin, direction, true)
	if not didThrow then
		return
	end

	local con
	con = model.Touched:Connect(function(otherPart)
		if model.AssemblyLinearVelocity.Magnitude < 0.5 then
			return con:Disconnect()
		end

		local otherModel = otherPart:FindFirstAncestorOfClass("Model")
		if not otherModel then
			return
		end

		local otherParticipant = attacker.Round:GetParticipant(otherModel.Name)
		if not otherParticipant then
			return
		end

		if otherParticipant == attacker then
			return
		end

		model:Destroy()

		otherParticipant:TryTakeDamage({
			Amount = DAMAGE,
			Attacker = attacker,
			Source = item,
		})
	end)

	attacker:RemoveItem(item)

	task.wait(1) -- wait, otherwise the attacker immediately picks up the knife

	local itemProp = attacker.Round:LoadItem(model)
	local newItem = itemProp.Item

	DNAScanner.AddDNATrace(newItem, attacker, nil, "rbxassetid://14930962070", model)
end

local item: Types.MeleeWeaponDefinition = {
	Kind = "Melee" :: "Melee",
	Name = "Knife",

	Description = "A sharp knife, capable of one-hit kills when stabbing or when thrown.",
	Icon = "rbxassetid://14930962070",

	Slot = 7,
	CanDrop = true,
	IsBadGuyItem = true,

	CreditCost = 1,
	MaxStock = 2,

	DamageKind = "Stab" :: "Stab",
	Damage = DAMAGE,

	MaxDistance = 7,
	AttackInterval = 0.75,
	AttackSound = ReplicatedStorage.Assets.WeaponSounds.Fired.Crowbar.SoundId,

	Model = ReplicatedStorage.Assets.WeaponModels.Knife,
	HoldAnimation = "rbxassetid://96501965592565",
    AttackAnimation = "rbxassetid://122463302312412",

	AlternateFireServer = throw,
	AlternateToggled = true,
}

return item