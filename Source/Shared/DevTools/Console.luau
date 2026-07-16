local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
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
		console.Object.Input.Text = text
	end
end

local function traverseHistoryDown(console: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Console)}): ()
	historyIndex = historyIndex % #commandHistory + 1

	local text = commandHistory[historyIndex]
	if text then
		console.Object.Input.Text = text
	end
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
					console.Object.Input:CaptureFocus()
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

				table.insert(historyConns, console.Object.Input.HistoryUp.Activated:Connect(function()
					traverseHistoryUp(console)
				end))

				table.insert(historyConns, console.Object.Input.HistoryDown.Activated:Connect(function()
					traverseHistoryDown(console)
				end))
			end

			return Enum.ContextActionResult.Sink
		end)

		local object = console.Object

		if not didConnect then
			didConnect = true
			object.Input.FocusLost:Connect(function(enterPressed)
				if not enterPressed then
					return
				end

				local input = object.Input.Text
				if input == "" then
					return
				end

				table.insert(commandHistory, input)
				historyIndex = #commandHistory + 1

				local result = Exec.ClientExecute(input)

				object.Output.Text = table.concat(result, "\n")
			end)

			object.Input:GetPropertyChangedSignal("Text"):Connect(function()
				object.Output.Text = ""
			end)
		end
	elseif console then
		console:Unregister()
	end
end, true)

return nil