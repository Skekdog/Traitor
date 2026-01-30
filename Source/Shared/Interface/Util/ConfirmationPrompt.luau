local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

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

local function ConfirmationPrompt(text: string, callback: (response: boolean) -> (), yesText: string?, noText: string?)
	prompt:ToggleVisible(false)
	prompt.Object.TextLabel.Text = text

	if yesCon then
		yesCon:Disconnect()
	end

	if noCon then
		noCon:Disconnect()
	end

	if yesText ~= "" then
		prompt.Object.Yes.Text = yesText or "Yes"
		prompt.Object.Yes.Visible = true
		yesCon = prompt.Object.Yes.Activated:Once(function()
			respond(true, callback)
		end)
	else
		prompt.Object.Yes.Visible = false
	end

	if noText ~= "" then
		prompt.Object.No.Text = noText or "No"
		prompt.Object.No.Visible = true
		noCon = prompt.Object.No.Activated:Once(function()
			respond(false, callback)
		end)
	else
		prompt.Object.No.Visible = false
	end

	prompt:ToggleVisible(true)
end

return ConfirmationPrompt