local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CustomActions = require(ReplicatedStorage.API.CustomActions)
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local GetRemote = require(ReplicatedStorage.API.GetRemote)

local currentMark: Highlight?

local remote = GetRemote("LoadMarking", script)

local params = RaycastParams.new()
params.IgnoreWater = true
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = "MouseInfoRay"

local function mark(): ()
	local camera = workspace.CurrentCamera
	local cameraSubject = camera.CameraSubject
	if cameraSubject and cameraSubject.Parent and cameraSubject:IsA("Humanoid") then
		params.FilterDescendantsInstances = {cameraSubject.Parent :: Model}
	else
		params.FilterDescendantsInstances = {}
	end

	local result = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 10000, params)
	if not result then
		return
	end

	local char = GetMapObject(result.Instance, "Character")
	if not char then
		return
	end

	if currentMark then
		currentMark:Destroy()
	end

	local mark = Instance.new("Highlight")
	mark.OutlineColor = Color3.fromRGB(255, 255, 255)
	mark.FillTransparency = 1
	mark.OutlineTransparency = 0
	mark.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	mark.Parent = char

	currentMark = mark
end

remote.OnClientEvent:Connect(function(active: boolean): ()
	if active then
		CustomActions.Register("Mark", mark, 2)
	else
		if currentMark then
			currentMark:Destroy()
		end
		CustomActions.Unregister("Mark")
	end
end)

return nil