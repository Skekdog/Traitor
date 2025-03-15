local function GetCentreRay(depth: number?): Ray
	local camera = workspace.CurrentCamera
    return camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2, depth)
end

return GetCentreRay