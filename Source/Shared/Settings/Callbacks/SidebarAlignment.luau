local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIAnimation = require(ReplicatedStorage.Shared.Interface.UILib.UIAnimation)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

return function(name: string, value: string): ()
	local ui = UIManager.WaitForUI("Sidebar").Object :: typeof(UIManager.UnregisteredUIs.Sidebar)

    local position, anchorPoint, textAlignment, paddingProperty
    if value == "Left" then
        position = UDim2.new(0, -5, 0.28, 0)
        anchorPoint = Vector2.new(0, 0)
        textAlignment = Enum.TextXAlignment.Right
        paddingProperty = "PaddingRight"
    elseif value == "Right" then
        position = UDim2.new(1, 5, 0.28, 0)
        anchorPoint = Vector2.new(1, 0)
        textAlignment = Enum.TextXAlignment.Left
        paddingProperty = "PaddingLeft"
    else
        error("Invalid alignment: " .. tostring(value))
    end

    UIAnimation.Animate(ui, TweenInfo.new(0.1), {Position = position, AnchorPoint = anchorPoint})

    for _, v in ui:QueryDescendants("UIListLayout, TextButton, TextLabel, ImageLabel") do
        if v:IsA("UIListLayout") then
            v.HorizontalAlignment = if value == "Right" then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Left
        elseif v:IsA("TextButton") then
            v.TextXAlignment = textAlignment;
            (v :: any).UIPadding[paddingProperty] = UDim.new(0, 8)
        elseif v:IsA("TextLabel") or v:IsA("ImageLabel") then
            (v :: GuiObject).LayoutOrder = if value == "Right" then 0 else 3
        end
    end
end