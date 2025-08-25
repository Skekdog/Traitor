
local module = {}

function module.Teleport(self, player: Player, cframe: CFrame | Vector3): ()
	local char = player.Character
	if char then
		char:PivotTo(if typeof(cframe) == "CFrame" then cframe else CFrame.new(cframe))
	end
end

return module