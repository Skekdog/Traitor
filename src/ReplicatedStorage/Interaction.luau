local RunService = game:GetService("RunService")
local ControlManager = require(script.Parent.ControlManager)
local LocalCharacter = require(script.Parent.LocalCharacter)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Mouse = require(script.Parent.Mouse)
local ShowAlert = require(script.Parent.ShowAlert)
local ViewCorpse = require(script.Parent.ViewCorpse)

local module = {}

module.InteractTarget = nil :: Instance?

local function interactCorpse(corpse: Model): boolean
	if corpse:GetAttribute("Burning") then
		ShowAlert("Ouch! This corpse is on fire!")
		return true
	end
	
	ViewCorpse(corpse)

	return true
end

function module.TryInteract(target: Instance?): boolean
	local map = LocalRoundInfo.GetMap()
	if not map then
		return false
	end

	if not target then
		return false
	end

	local model = target:FindFirstAncestorOfClass("Model")
	if model and model:IsDescendantOf(workspace.Corpses) then
		return interactCorpse(model)
	end

	local char = LocalCharacter.GetCharacter()
	if not char then
		return false
	end
	
	return false
end

ControlManager.Register("Interact", function(action, state, input)
	return if module.TryInteract(module.InteractTarget) then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
end)

local params = RaycastParams.new()
params.IgnoreWater = true
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = "Raycasts"

RunService.PostSimulation:Connect(function()
	local camera = workspace.CurrentCamera
	local cameraSubject = camera.CameraSubject
	if cameraSubject and cameraSubject.Parent and cameraSubject:IsA("Humanoid") then
		params.FilterDescendantsInstances = {cameraSubject.Parent}
	end

	local map = LocalRoundInfo.GetMap()
	if map then
		params:AddToFilter(map.Bounds)
	end
	
    local result = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 10000, params)
	-- 10000 distance because we should still be able to see players. Corpses can be viewed from distance 10, so we include that as a check there.

	Mouse.Reset()
	
    if result then
        module.InteractTarget = result.Instance
        assert(module.InteractTarget)

		if map then
			if module.InteractTarget:IsDescendantOf(map.ItemSpawns) or module.InteractTarget:IsDescendantOf(map.AmmoSpawns) then
				Mouse.ShowItemHint(module.InteractTarget)
			end
		end

        local char = module.InteractTarget:FindFirstAncestorOfClass("Model")
        if not char then
            return
        end

        if char:IsDescendantOf(workspace.Corpses) then
            Mouse.ShowCorpseHint(char)
        elseif char:IsDescendantOf(workspace.Characters) then
            Mouse.ShowPlayerInfo(char)
        end

        return
    end
    module.InteractTarget = nil
end)

return module