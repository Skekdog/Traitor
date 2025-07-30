
local function TraitorNode(object: Script, tip: string, cost: number, interval: number, radius: number, callback: (Player) -> ()): ()
	local part = object:FindFirstAncestorWhichIsA("BasePart")
	if not part then
		local model = object:FindFirstAncestorWhichIsA("Model")
		if model then
			part = model.PrimaryPart
		end

		if not part then
			return
		end
	end
end

return TraitorNode