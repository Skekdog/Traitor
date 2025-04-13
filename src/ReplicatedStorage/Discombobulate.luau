
local function get(): number
	return math.rad((if math.random() > 0.5 then -1 else 1) * math.random(45, 180))
end

local function Discombobulate(): ()
	local camera = workspace.CurrentCamera
	local x, y, z = camera.CFrame:ToEulerAnglesXYZ()
	camera.CFrame = CFrame.Angles(x + get(), y + get(), z + get()) + camera.CFrame.Position
end

return Discombobulate