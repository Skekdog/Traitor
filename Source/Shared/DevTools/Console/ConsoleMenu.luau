local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ClientArguments = require(script.Parent.ClientArguments)
local Commands = require(script.Parent.Commands)
local Exec = require(script.Parent.Exec)
local Lexer = require(script.Parent.Lexer)
local Parser = require(script.Parent.Parser)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local IsAdmin = require(ReplicatedStorage.Shared.DevTools.IsAdmin)
local RelaxedPermissions = require(ReplicatedStorage.Shared.DevTools.RelaxedPermissions)
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

local function highlightText(text: string, colour: Color3): string
	return `<font color='{colour:ToHex()}'>{text}</font>`
end

type HighlightKind = "Error"

local highlightColours: {[HighlightKind]: Color3} = {
	["Error"] = Color3.fromRGB(255, 0, 0),
}

type HighlightInfo = {span: vector, kind: HighlightKind}
local function applyHighlighting(input: string, highlights: {HighlightInfo}): string
	local parts: {string} = {}

	local lastSpan = vector.create(0, 0)
	for i, params in highlights do
		local span = params.span

		local previous = string.sub(input, lastSpan.y + 1, span.x - 1)
		lastSpan = span

		table.insert(parts, previous)

		local current = string.sub(input, span.x, span.y)
		table.insert(parts, highlightText(current, highlightColours[params.kind]))
	end

	return table.concat(parts, "")
end

local function processTokens(input: string): {Rendered: string, Output: string}
	local parseResult = Parser.Parse(input, Lexer.Lex(input))
	if not parseResult.ok then
		return {Rendered = input, Output = parseResult.err}
	end

	local output: {string} = {}

	local currentCommand: Commands.Command?
	local requiredArguments = 0
	local argumentIndex = 0

	local highlights: {HighlightInfo} = {}

	for _, token in parseResult.tokens do
		if token.kind == "COMMAND" then
			local name = token.parsed_content

			if currentCommand and argumentIndex < requiredArguments then
				table.insert(output, `Expected at least {requiredArguments} arguments`)
			end

			requiredArguments = 0
			argumentIndex = 0
			currentCommand = Commands[name]

			if currentCommand then
				for _, types in currentCommand.Types do
					local casted = (types :: any) :: {string}
					if not table.find(casted, "optional") and not table.find(casted, "players") then
						requiredArguments += 1
					end
				end
			end

			if not currentCommand then
				table.insert(highlights, {
					span = token.span,
					kind = "Error",
				})

				table.insert(output, "Unknown command: " .. name)
			end
		elseif token.kind == "ARGUMENT" and currentCommand then
			local argument = token.parsed_content

			argumentIndex += 1

			local argumentValidation = ClientArguments.IsValidArgument(currentCommand, argument, argumentIndex)
			if argumentValidation then
				table.insert(highlights, {
					span = token.span,
					kind = "Error",
				})
				table.insert(output, argumentValidation)
			end
		end
	end

	if currentCommand and argumentIndex < requiredArguments then
		table.insert(output, `Expected at least {requiredArguments} arguments`)
	end

	return {Rendered = applyHighlighting(input, highlights), Output = table.concat(output, "\n")}
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