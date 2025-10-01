
-- from: https://devforum.roblox.com/t/how-to-ensure-a-plain-text-string-when-using-rich-text-field/1640202/3

local function EscapeRichText(s: string): string
	s = string.gsub( s, "&",  "&amp;" ) -- (must do & first)
	s = string.gsub( s, "<",  "&lt;" )
	s = string.gsub( s, ">",  "&gt;" )
	s = string.gsub( s, "\"", "&quot;" )
	s = string.gsub( s, "'",  "&apos;" )
	return s
end

return EscapeRichText