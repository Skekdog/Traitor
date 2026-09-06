local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ClientArguments = require(script.Parent.ClientArguments)
local Commands = require(script.Parent.Commands)
local IsAdmin = require(script.Parent.IsAdmin)
local RelaxedPermissions = require(script.Parent.RelaxedPermissions)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local Exec = require(ReplicatedStorage.Shared.DevTools.Exec)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local commandHistory: {string?} = {}
local historyIndex = 0

local historyConns: {RBXScriptConnection} = {}

local didConnect = false
local console: (UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Console)})?

local function traverseHistoryUp(console: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Console)}): ()
	historyIndex = (historyIndex - 2) % #commandHistory + 1

	local text = commandHistory[historyIndex]
	if text then
		console.Object.InputFrame.TextInputFrame.Input.Text = text
	end
end

local function traverseHistoryDown(console: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Console)}): ()
	historyIndex = historyIndex % #commandHistory + 1

	local text = commandHistory[historyIndex]
	if text then
		console.Object.InputFrame.TextInputFrame.Input.Text = text
	end
end

local function errorHighlight(text: string): string
	return "<font color='#ff0000'>" .. text .. "</font>"
end

local function processTokens(input: string): {Rendered: string, Output: string}
	local tokens = Exec.Tokenise(input)

	local rendered = ""
	local output: {string} = {}

	local currentCommand: Commands.Command?
	local argumentIndex = 0
	for _, token in tokens do
		local renderedToken = token.Value

		if token.Kind == "CommandName" then
			local name = token.Value

			argumentIndex = 0
			currentCommand = Commands[name]

			if not currentCommand then
				renderedToken = errorHighlight(name)
				table.insert(output, "Unknown command: " .. name)
			end
		elseif token.Kind == "Argument" and currentCommand then
			local argument = token.Value

			argumentIndex += 1

			local argumentValidation = ClientArguments.IsValidArgument(currentCommand, argument, argumentIndex)
			if argumentValidation then
				renderedToken = errorHighlight(argument)
				table.insert(output, argumentValidation)
			end
		end

		rendered ..= renderedToken
	end

	return {Rendered = rendered, Output = table.concat(output, "\n")}
end

RelaxedPermissions.TemporaryPermissions:Connect(function(perms)
	if RelaxedPermissions.HasRelaxedPermissions(Players.LocalPlayer) or IsAdmin(Players.LocalPlayer) then
		-- we need true here because otherwise console is incorrectly refined to "nil" / "never" later in the code.
		if true and console then
			return
		end

		console = UIManager.RegisterUI(UIManager.UnregisteredUIs.Console) :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Console)}
		assert(console)

		ControlManager.Register("Console", function()
			console:ToggleVisible()

			for _, conn in historyConns do
				conn:Disconnect()
			end
			table.clear(historyConns)

			if console.Visible then
				task.spawn(function()
					task.wait()
					console.Object.InputFrame.TextInputFrame.Input:CaptureFocus()
				end)

				table.insert(historyConns, UserInputService.InputEnded:Connect(function(input, proc)
					if not proc then
						return
					end

					if input.KeyCode == Enum.KeyCode.Up then
						traverseHistoryUp(console)
					elseif input.KeyCode == Enum.KeyCode.Down then
						traverseHistoryDown(console)
					end
				end))

				table.insert(historyConns, console.Object.InputFrame.HistoryUp.Activated:Connect(function()
					traverseHistoryUp(console)
				end))

				table.insert(historyConns, console.Object.InputFrame.HistoryDown.Activated:Connect(function()
					traverseHistoryDown(console)
				end))
			end

			return Enum.ContextActionResult.Sink
		end)

		local object = console.Object

		if not didConnect then
			didConnect = true
			object.InputFrame.TextInputFrame.Input.FocusLost:Connect(function(enterPressed)
				if not enterPressed then
					return
				end

				local input = object.InputFrame.TextInputFrame.Input.Text
				if input == "" then
					return
				end

				table.insert(commandHistory, input)
				historyIndex = #commandHistory + 1

				local result = Exec.ClientExecute(input)

				object.OutputHolder.OutputScroll.Output.Text = table.concat(result, "\n")
			end)

			object.InputFrame.TextInputFrame.Input:GetPropertyChangedSignal("Text"):Connect(function()
				local output = object.OutputHolder.OutputScroll.Output
				local input = object.InputFrame.TextInputFrame.Input.Text
				local renderedInput = object.InputFrame.TextInputFrame.RenderedInput

				local result = processTokens(input)

				renderedInput.Text = result.Rendered
				output.Text = result.Output
			end)
		end
	elseif console then
		console:Unregister()
	end
end, true)

return nil