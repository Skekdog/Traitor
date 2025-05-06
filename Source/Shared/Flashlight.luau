local ControlManager = require(script.Parent.ControlManager)
local LocalCharacter = require(script.Parent.LocalCharacter)

local function tryGetAttachment(root: BasePart): Attachment?
	local attachment = root:FindFirstChild("FlashlightAttachment")
	if not attachment then
		return nil
	end

	assert(attachment:IsA("Attachment"))

	return attachment
end

local function getOrCreateFlashlight(root: BasePart): SpotLight
	local attachment = tryGetAttachment(root)
	if not attachment then
		local newAttachment = Instance.new("Attachment")
		newAttachment.Name = "FlashlightAttachment"
		newAttachment.Position = Vector3.new(0, 1.5, 0)
		newAttachment.Parent = root
		attachment = newAttachment
	end
	assert(attachment and attachment:IsA("Attachment"))

	local light = attachment:FindFirstChild("Flashlight")
	if not light then
		local newLight = Instance.new("SpotLight")
		newLight.Name = "Flashlight"
		newLight.Face = Enum.NormalId.Front
		newLight.Range = 30
		newLight.Brightness = 5
		newLight.Shadows = true
		newLight.Angle = 45
		newLight.Parent = attachment
		light = newLight
	end
	assert(light and light:IsA("SpotLight"))

	return light
end

local enabled = false
local function enableFlashlight(): Enum.ContextActionResult
	enabled = not enabled

	local root = LocalCharacter.RootPart()
	if not root then
		enabled = false
		return Enum.ContextActionResult.Pass
	end

	local light = getOrCreateFlashlight(root)
	light.Enabled = enabled

	return Enum.ContextActionResult.Sink
end

LocalCharacter.Character:Connect(function(char)
	if not char then
		ControlManager.Unregister("Flashlight")
		return
	end
	ControlManager.Register("Flashlight", enableFlashlight)
end)

local function onCameraCFrameChanged(): ()
	if not enabled then
		return
	end

	local root = LocalCharacter.RootPart()
	if not root then
		return
	end

	local attachment = tryGetAttachment(root)
	if not attachment then
		return
	end

	local x = workspace.CurrentCamera.CFrame:ToOrientation()
	attachment.CFrame = CFrame.new(attachment.CFrame.Position) * CFrame.fromEulerAnglesYXZ(x, 0, 0)
end

local lastCameraCon: RBXScriptConnection?
local function listenToCamera(): ()
	if lastCameraCon then
		lastCameraCon:Disconnect()
	end

	lastCameraCon = workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Connect(onCameraCFrameChanged)
	onCameraCFrameChanged()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(listenToCamera)
listenToCamera()

return nil