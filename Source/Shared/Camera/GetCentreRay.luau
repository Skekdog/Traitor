local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function GetCentreRay(depth: number?, useCamera: boolean?): Ray
	local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)

	local camera = workspace.CurrentCamera
	local cameraRay = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2, depth)

	local head = LocalCharacter.Head()
	if not head or useCamera then
		return cameraRay
	end

    return Ray.new(head.Position, cameraRay.Direction)
end

return GetCentreRay