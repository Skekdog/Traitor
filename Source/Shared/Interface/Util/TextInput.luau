local UIManager = require(script.Parent.Parent.UILib.UIManager)

local textInput = {}

local ui = UIManager.WaitForUI("TextInput") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.TextInput)}
local object = ui.Object.Frame

local box = object.TextBox
local confirm = object.TextButton
local cancel = object.CancelButton

local cons: {RBXScriptConnection} = {}
local val: NumberValue?

function textInput.Create(text: string, inputType: "Number", range: string, context: string): number?
	box.Text = ""
	box.PlaceholderText = `{text} ({range})`
	ui:ToggleVisible(true)

	for _, v in cons do
		v:Disconnect()
	end
	cons = {}

	if val then
		val:Destroy()
	end

	val = Instance.new(inputType.."Value") :: NumberValue
	assert(val)

	local min = tonumber(string.split(range, "-")[1]) :: number
	local max = tonumber(string.split(range, "-")[2]) :: number

	table.insert(cons, confirm.MouseButton1Click:Once(function()
		local num = tonumber(box.Text)
		if inputType == "Number" then
			if num then
				val.Value = math.clamp(num, min, max)
			end
			return
		end
	end))

	table.insert(cons, cancel.MouseButton1Click:Once(function()
		val.Value = -math.huge
	end))

	val.Changed:Wait()

	ui:ToggleVisible(false)

	return if val.Value == -math.huge then nil else val.Value
end

return textInput