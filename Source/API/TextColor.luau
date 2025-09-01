
local function TextColor(text: string, colour: Color3): string
	return `<font color='#{colour:ToHex()}'>{text}</font>`
end

return TextColor