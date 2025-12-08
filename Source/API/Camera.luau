local Players = game:GetService("Players")

local Camera = {}

local THIRD_PERSON_MAX_ZOOM = 128
local THIRD_PERSON_MIN_ZOOM = 0.5

local ANIMATION_VIEW_ZOOM = 10

local player = Players.LocalPlayer

function Camera.EnterAnimationView(): ()
	player.CameraMinZoomDistance = ANIMATION_VIEW_ZOOM
	player.CameraMaxZoomDistance = ANIMATION_VIEW_ZOOM
	player.CameraMode = Enum.CameraMode.Classic
end

function Camera.EnterFirstPerson(): ()
	player.CameraMinZoomDistance = THIRD_PERSON_MAX_ZOOM
	player.CameraMaxZoomDistance = THIRD_PERSON_MIN_ZOOM
	player.CameraMode = Enum.CameraMode.LockFirstPerson
end

function Camera.EnterThirdPerson(): ()
	player.CameraMinZoomDistance = THIRD_PERSON_MAX_ZOOM
	player.CameraMaxZoomDistance = THIRD_PERSON_MIN_ZOOM
	player.CameraMode = Enum.CameraMode.Classic
end

return Camera