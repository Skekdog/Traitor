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

	local root = LocalCharacter.GetRootPart()
	if not root then
		enabled = false
		return Enum.ContextActionResult.Pass
	end

	local light = getOrCreateFlashlight(root)
	light.Enabled = enabled

	return Enum.ContextActionResult.Sink
end

LocalCharacter.CharacterAdded:Connect(function(char: Model)
	ControlManager.Register("Flashlight", enableFlashlight)
end)

LocalCharacter.CharacterRemoving:Connect(function()
	ControlManager.Unregister("Flashlight")
end)

local lastCameraCon: RBXScriptConnection?
local function listenToCamera(): ()
	local camera = workspace.CurrentCamera

	if lastCameraCon then
		lastCameraCon:Disconnect()
	end

	lastCameraCon = camera:GetPropertyChangedSignal("CFrame"):Connect(function()
		if not enabled then
			return
		end
	
		local root = LocalCharacter.GetRootPart()
		if not root then
			return
		end
	
		local attachment = tryGetAttachment(root)
		if not attachment then
			return
		end
	
		local x = workspace.CurrentCamera.CFrame:ToOrientation()
		attachment.CFrame = CFrame.new(attachment.CFrame.Position) * CFrame.fromEulerAnglesYXZ(x, 0, 0)
	end)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(listenToCamera)
listenToCamera()

return nil