local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Commands = require(script.Parent.Commands)
local IsAdmin = require(script.Parent.IsAdmin)
local RelaxedPermissions = require(script.Parent.RelaxedPermissions)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local Exec = require(ReplicatedStorage.Shared.DevTools.Exec)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local PlaceIDs = require(ReplicatedStorage.Shared.Places.PlaceIDs)

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

local function isValidType(argument: string, type: Commands.ArgumentType): string?
	if type == "place" then
		return if PlaceIDs[argument] then nil else "place"
	elseif type == "number" then
		return if tonumber(argument) then nil else "number"
	end

	return "unknown"
end

local function isValidArgument(command: Commands.Command, argument: string, index: number): string?
	local types = command.Types[index]
	if not types and command.Arguments[#command.Arguments] ~= "..." then
		return "Expected at most " .. #command.Arguments .. "arguments"
	elseif not types then
		types = command.Types[#command.Arguments]
		if not types then
			return nil
		end
	end

	assert(types)

	if table.find(types, "string") or table.find(types, "any") then
		return nil -- Any string is valid input. Obviously any any is also valid
	end

	local failedTypes: {string} = {}

	for _, type in types do
		local result = isValidType(argument, type :: Commands.ArgumentType)
		if not result then
			-- As soon as one matches, we are clear of any errors on this argument
			return nil
		end

		table.insert(failedTypes, result)
	end

	return "Expected " .. table.concat(failedTypes, ", ")
end

local function processTokens(input: string): {Rendered: string, Output: string}
	local tokens = Exec.Tokenise(input)

	local rendered = ""
	local output = ""

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
				output = "Unknown command: " .. name
			end
		elseif token.Kind == "Argument" and currentCommand then
			local argument = token.Value

			argumentIndex += 1

			local argumentValidation = isValidArgument(currentCommand, argument, argumentIndex)
			if argumentValidation then
				renderedToken = errorHighlight(argument)
				if output == "" then
					output = argumentValidation
				end
			end
		end

		rendered ..= renderedToken
	end

	return {Rendered = rendered, Output = output}
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