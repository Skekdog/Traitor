
local function Teleporter(targetPart: BasePart, destination: CFrame): ()
	targetPart.Touched:Connect(function(otherPart: BasePart): ()
		local char = otherPart:FindFirstAncestorOfClass("Model")
		if not char then
			return
		end

		char:PivotTo(destination)
	end)
end

return Teleporter