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
	clone.Parent = game:GetService("Players").LocalPlayer.PlayerGui
	
	local val = Instance.new(inputType.."Value")
	val.Parent = clone
	
	local min = string.split(range, "-")[1]
	local max = string.split(range, "-")[2]
	
	but.MouseButton1Click:Once(function()
		local num = tonumber(box.Text)
		if inputType == "Number" then
			if num then
				val.Value = math.clamp(num,min,max)
			end
			return
		end
		val.Value = box.Text
	end)
	
	can.MouseButton1Click:Once(function()
		val.Value = tonumber("-inf")
		clone:Destroy()
	end)
	
	val.Changed:Wait()
	clone:Destroy()
	return if val.Value ~= tonumber("-inf") then val.Value else nil
end

return textInput