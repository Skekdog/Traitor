local textInput = {}

local index = 0
function textInput.Create(text:string,inputType:"Number",range:string,context:string): any?
	index = index + 1
	local clone = script:FindFirstChild("TextInput"):Clone()
	local can = clone.Darken.CancelButton
	local but = clone.Darken.TextButton
	local box = clone.Darken.TextBox
	
	box.PlaceholderText = text.." ("..range..")"
	clone.Enabled = true
	clone.Name = context..inputType.."TextInput"..tostring(index)
	clone.Parent = game:GetService("Players").LocalPlayer.PlayerGui
	
	local val: any = Instance.new(inputType.."Value")
	val.Parent = clone
	
	local min = string.split(range,"-")[1]
	local max = string.split(range,"-")[2]
	
	local con
	con = but.MouseButton1Click:Connect(function()
		local num = tonumber(box.Text)
		if inputType == "Number" then
			if num then
				val.Value = math.clamp(num,min,max)
				return
			else
				return
			end
		end
		val.Value = box.Text
	end)
	
	local cancelCon
	cancelCon = can.MouseButton1Click:Connect(function()
		con:Disconnect()
		cancelCon:Disconnect()
		clone:Destroy()
		return nil
	end)
	
	val.Changed:Wait()
	cancelCon:Disconnect()
	con:Disconnect()
	clone:Destroy()
	return val.Value
end

return textInput