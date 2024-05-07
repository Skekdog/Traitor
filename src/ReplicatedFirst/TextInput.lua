local Players = game:GetService("Players")
local textInput = {}

local index = 0
function textInput.Create(text: string, inputType: "Number", range: string, context: string): any?
	index = index + 1
	local clone = script:FindFirstChild("TextInput"):Clone()
	local can = clone.Darken.CancelButton
	local but = clone.Darken.TextButton
	local box = clone.Darken.TextBox
	
	box.PlaceholderText = `{text} ({range})`
	clone.Enabled = true
	clone.Name = `{context}{inputType}TextInput{index}`
	clone.Parent = Players.LocalPlayer.PlayerGui :: any
	
	local val = Instance.new(inputType.."Value") :: NumberValue
	val.Parent = clone
	
	local min = tonumber(string.split(range, "-")[1]) :: number
	local max = tonumber(string.split(range, "-")[2]) :: number
	
	but.MouseButton1Click:Once(function()
		local num = tonumber(box.Text)
		if inputType == "Number" then
			if num then
				val.Value = math.clamp(num, min, max)
			end
			return
		end
		val.Value = tonumber(box.Text) :: number
	end)
	
	can.MouseButton1Click:Once(function()
		val.Value = tonumber("-inf") :: number
		clone:Destroy()
	end)
	
	val.Changed:Wait()
	clone:Destroy()
	return if val.Value ~= tonumber("-inf") then val.Value else nil
end

return textInput