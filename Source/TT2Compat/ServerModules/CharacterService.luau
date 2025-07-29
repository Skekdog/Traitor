
local module = {}

function module.Teleport(self, player: Player, cframe: CFrame): ()
	local char = player.Character
	if char then
		char:PivotTo(cframe)
	end
end

return module