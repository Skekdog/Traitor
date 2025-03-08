local UIManager = require(script.Parent.UIManager)

local prompt = UIManager.WaitForUI("ConfirmationPrompt") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.ConfirmationPrompt)}

local yesCon: RBXScriptConnection?
local noCon: RBXScriptConnection?

local function respond(response: boolean, callback: (response: boolean) -> ())
	if yesCon then
		yesCon:Disconnect()
	end

	if noCon then
		noCon:Disconnect()
	end

	prompt:ToggleVisible(false)
	callback(response)
end

local function ConfirmationPrompt(text: string, callback: (response: boolean) -> ())
	prompt:ToggleVisible(false)
	prompt.Object.TextLabel.Text = text

	if yesCon then
		yesCon:Disconnect()
	end

	if noCon then
		noCon:Disconnect()
	end

	yesCon = prompt.Object.Yes.Activated:Once(function()
		respond(true, callback)
	end)

	noCon = prompt.Object.No.Activated:Once(function()
		respond(false, callback)
	end)

	prompt:ToggleVisible(true)
end

return ConfirmationPrompt