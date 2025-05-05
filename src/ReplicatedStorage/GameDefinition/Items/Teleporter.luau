local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.RoundRule.Types)

local MAX_USES = 6

type Teleporter = Types.Item & {
	Extras: {
		TimesUsed: number?,
		Target: CFrame?,
		[any]: never,
	}
}

local function PrimaryFireServer(item: Types.Item | Teleporter, _, _, _, participant: Types.Participant): ()
	local teleporter = item :: Teleporter

	if not teleporter.Extras.Target or ((teleporter.Extras.TimesUsed or 0) >= MAX_USES) then
		return
	end

	local char = participant:GetCharacter()
	if not char then
		return
	end

	teleporter.Extras.TimesUsed = (teleporter.Extras.TimesUsed or 0) + 1
	char:PivotTo(teleporter.Extras.Target)
end

local function AlternateFireServer(item: Types.Item | Teleporter, _, _, _, participant: Types.Participant): ()
	local teleporter = item :: Teleporter

	local char = participant:GetCharacter()
	if not char then
		return
	end

	teleporter.Extras.Target = char:GetPivot()
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "Teleporter",
	Description = "Can be used to teleport a limited number of times, after marking a target location.",
	Icon = "rbxassetid://62159372",
	Slot = 8,

	CreditCost = 1,
	MaxStock = 1,

	PrimaryToggled = true,
	PrimaryHint = "Deploy Teleporter",
	PrimaryFireServer = PrimaryFireServer,

	AlternateToggled = true,
	AlternateHint = "Mark Location",
	AlternateFireServer = AlternateFireServer,
}

return item