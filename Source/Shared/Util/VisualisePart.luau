
local function VisualisePart(cframe: CFrame, size: Vector3): ()
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 0.5
	part.Color = Color3.new(0, 0, 1)
	part.CFrame = cframe
	part.Size = size
	part.Parent = workspace
	task.delay(5, part.Destroy, part)
end

return VisualisePart