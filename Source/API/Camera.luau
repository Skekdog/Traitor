local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local CameraModule = require(StarterPlayer.PlayerModule.CameraModule)
local ZoomController = require(StarterPlayer.PlayerModule.CameraModule.ZoomController)

local Camera = {}

local THIRD_PERSON_MAX_ZOOM = 128
local THIRD_PERSON_MIN_ZOOM = 0.5

local ANIMATION_VIEW_ZOOM = 10

local player = Players.LocalPlayer

function Camera.IsFirstPerson(): boolean
	return player.CameraMode == Enum.CameraMode.LockFirstPerson
end

function Camera.EnterAnimationView(): ()
	player.CameraMinZoomDistance = ANIMATION_VIEW_ZOOM
	player.CameraMaxZoomDistance = ANIMATION_VIEW_ZOOM
	player.CameraMode = Enum.CameraMode.Classic
end

function Camera.EnterFirstPerson(): ()
	player.CameraMinZoomDistance = THIRD_PERSON_MIN_ZOOM
	player.CameraMaxZoomDistance = THIRD_PERSON_MAX_ZOOM
	player.CameraMode = Enum.CameraMode.LockFirstPerson
end

type CameraModule = {
	activeCameraController: {
		SetCameraToSubjectDistance: (self: any, number) -> (),
	},
}

function Camera.EnterThirdPerson(maxZoom: number?): ()
	player.CameraMinZoomDistance = THIRD_PERSON_MIN_ZOOM
	player.CameraMaxZoomDistance = maxZoom or THIRD_PERSON_MAX_ZOOM
	player.CameraMode = Enum.CameraMode.Classic

	local targetZoom = math.min(2, maxZoom or THIRD_PERSON_MAX_ZOOM)

	local cameraController = ((CameraModule :: any) :: CameraModule).activeCameraController
	if cameraController then
		cameraController:SetCameraToSubjectDistance(targetZoom)
	end

	ZoomController.SetZoomParameters(targetZoom, if ZoomController.GetZoomRadius() > targetZoom then -1 else 1)
end

return table.freeze(Camera)