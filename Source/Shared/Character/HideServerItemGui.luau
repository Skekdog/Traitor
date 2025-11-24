local LocalCharacter = require(script.Parent.LocalCharacter)

local function hide(child: Instance): ()
	if child:IsA("LayerCollector") and child:FindFirstAncestor("Item") then
		child.Enabled = false
	end
end

LocalCharacter.Character:Connect(function(char)
	if not char then
		return
	end

	char.DescendantAdded:Connect(function(child)
		hide(child)
	end)
end, true)

return nil