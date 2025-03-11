local ControlManager = require(script.Parent.ControlManager)
local LocalCharacter = require(script.Parent.LocalCharacter)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Mouse = require(script.Parent.Mouse)
local ShowAlert = require(script.Parent.ShowAlert)
local ViewCorpse = require(script.Parent.ViewCorpse)

local module = {}

local function interactCorpse(corpse: Model): boolean
	if corpse:GetAttribute("Burning") then
		ShowAlert("Ouch! This corpse is on fire!")
		return true
	end
	
	ViewCorpse(corpse)

	return true
end

function module.TryInteract(target: Instance): boolean
	if not target then
		return false
	end

	local map = LocalRoundInfo.GetMap()

	if not map then
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
    if not Mouse.InteractTarget then
        return Enum.ContextActionResult.Pass
    end

	return if module.TryInteract(Mouse.InteractTarget) then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
end)

return module