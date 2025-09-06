local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)

local function tryGetAttachment(root: Instance): Attachment?
	local attachment = root:FindFirstChild("FlashlightAttachment")
	if not attachment then
		return nil
	end

	assert(attachment:IsA("Attachment"))

	return attachment
end

local function getOrCreateFlashlight(root: Instance): Light
	local attachment = tryGetAttachment(root)
	if not attachment then
		local newAttachment = Instance.new("Attachment")
		newAttachment.Name = "FlashlightAttachment"
		newAttachment.Parent = root
		attachment = newAttachment
	end
	assert(attachment and attachment:IsA("Attachment"))

	local light = attachment:FindFirstChild("Flashlight")
	if not light then
		local newLight = Instance.new("PointLight")
		newLight.Name = "Flashlight"
		newLight.Range = 12
		newLight.Brightness = 1
		newLight.Shadows = true
		newLight.Parent = attachment
		light = newLight
	end

	assert(light and light:IsA("Light"))

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

	local light = getOrCreateFlashlight(workspace.CurrentCamera)
	light.Enabled = enabled

	return Enum.ContextActionResult.Sink
end

LocalCharacter.Character:Connect(function(char)
	if not char then
		ControlManager.Unregister("Flashlight")

		local attachment = tryGetAttachment(workspace.CurrentCamera)
		if attachment then
			attachment:Destroy()
		end

		enabled = false

		return
	end
	ControlManager.Register("Flashlight", enableFlashlight)
end)

return nil