local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)
local ControlManager = require(script.Parent.ControlManager)
local boundInstances: {[string]: {Instance}} = {}

type Label = TextLabel | ImageLabel

local function setTextForTextLabel(text: string, label: TextLabel, instance: Instance): ()
    if text == "" or text == "NONE" and instance:GetAttribute("HideNone") then
        label.Text = ""
        return
    end
    label.Text = `[{text}]`
end

local function setImageForImageLabel(image: string, label: ImageLabel): ()
    label.Image = image
end

local function createLabel(class: "TextLabel" | "ImageLabel", control: string, instance: Instance, position: UDim2?, size: UDim2?, anchorPoint: Vector2?, noStyle: boolean?, textXAlignment: string?): Label
    local label = Instance.new(class) :: GuiObject

    label.Position = position or UDim2.fromScale(1, 0)
    label.AnchorPoint = anchorPoint or Vector2.new(0.5, 0.5)
    label.Size = size or UDim2.fromScale(0.45, 0.6)
    label.BackgroundTransparency = 1
    label.Visible = false

    if class == "TextLabel" then
        assert(label:IsA("TextLabel"))
        label.Name = "KeybindHintText"

        label.TextScaled = true
        label.Font = Enum.Font.BuilderSans
        label.TextStrokeTransparency = 0
        label.AutomaticSize = Enum.AutomaticSize.X
        label.TextXAlignment = (Enum :: any).TextXAlignment[textXAlignment or "Center"]

        if not noStyle then
            label:AddTag("StyledUI")
        else
            label.TextColor3 = Color3.new(1, 1, 1)
        end
    elseif class == "ImageLabel" then
        assert(label:IsA("ImageLabel"))
        label.ScaleType = Enum.ScaleType.Fit
        label.Name = "KeybindHintImage"

        do
            local uiAspectRatio = Instance.new("UIAspectRatioConstraint")
            uiAspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
            uiAspectRatio.DominantAxis = Enum.DominantAxis.Height
            uiAspectRatio.Parent = label
        end

        if not noStyle then
            label:AddTag("StyledUI")
        else
            label.ImageColor3 = Color3.new(1, 1, 1)
        end
    end

    label.Parent = instance

    return label :: Label
end

local function updateText(control: string, instance: Instance): ()
    local text = ControlManager.GetFirstKeyCode(control, if instance:GetAttribute("AlwaysShow") then false else true)

    local imageLabel = instance:FindFirstChild("KeybindHintImage") :: ImageLabel?
    local textLabel = instance:FindFirstChild("KeybindHintText") :: TextLabel?

    if text:find("://") then
        if not imageLabel then
            return
        end

        if textLabel then
            textLabel.Visible = false
        end

        imageLabel.Visible = true
        setImageForImageLabel(text, imageLabel)
    else
        if not textLabel then
            return
        end

        if imageLabel then
            imageLabel.Visible = false
        end

        textLabel.Visible = true
        setTextForTextLabel(text, textLabel, instance)
    end
end

local function createLabels(control: string, instance: Instance, position: UDim2?, size: UDim2?, anchorPoint: Vector2?, noStyle: boolean?, textXAlignment: string?): ()
    createLabel("ImageLabel", control, instance, position, size, anchorPoint, noStyle, textXAlignment)
    createLabel("TextLabel", control, instance, position, size, anchorPoint, noStyle, textXAlignment)

    if not boundInstances[control] then
        boundInstances[control] = {}
    end
    table.insert(boundInstances[control], instance)

    updateText(control, instance)
end

local function loadInstance(instance: Instance): ()
    local control = instance:GetAttribute("Control") :: string?
    assert(typeof(control) == "string", "Expected attribute 'Control' to be a string: " .. instance:GetFullName())

    local definition = Settings.GetDefinition(control)
    assert(definition, "Control not found: " .. control .. " " .. instance:GetFullName())

    local position = instance:GetAttribute("Position") :: UDim2?
    assert(typeof(position) == "UDim2" or position == nil, "Expected attribute 'Position' to be a UDim2 or nil " .. instance:GetFullName())

    local size = instance:GetAttribute("Size") :: UDim2?
    assert(typeof(size) == "UDim2" or size == nil, "Expected attribute 'Size' to be a UDim2 or nil " .. instance:GetFullName())

    local anchorPoint = instance:GetAttribute("AnchorPoint") :: Vector2?
    assert(typeof(anchorPoint) == "Vector2" or anchorPoint == nil, "Expected attribute 'AnchorPoint' to be a Vector2 or nil " .. instance:GetFullName())

    local textXAlignment = instance:GetAttribute("TextXAlignment") :: "Left" | "Right" | "Center"?
    assert(textXAlignment == "Left" or textXAlignment == "Right" or textXAlignment == "Center" or textXAlignment == nil, "Expected attribute 'TextXAlignment' to be a 'Left' | 'Right' | 'Center' or nil " .. instance:GetFullName())

    local noStyle = instance:GetAttribute("NoStyle") :: boolean?
    assert(typeof(noStyle) == "boolean" or noStyle == nil, "Expected attribute 'NoStyle' to be a boolean or nil " .. instance:GetFullName())

    local alwaysShow = instance:GetAttribute("AlwaysShow") :: boolean?
    assert(typeof(alwaysShow) == "boolean" or alwaysShow == nil, "Expected attribute 'AlwaysShow' to be a boolean or nil " .. instance:GetFullName())

    local hideNone = instance:GetAttribute("HideNone") :: boolean?
    assert(typeof(hideNone) == "boolean" or hideNone == nil, "Expected attribute 'HideNone' to be a boolean or nil " .. instance:GetFullName())

    createLabels(control, instance, position, size, anchorPoint, noStyle, textXAlignment)
end

CollectionService:GetInstanceAddedSignal("ControlHint"):Connect(loadInstance)
for _, v in CollectionService:GetTagged("ControlHint") do
    loadInstance(v)
end

CollectionService:GetInstanceRemovedSignal("ControlHint"):Connect(function(instance)
    local hintLabel = instance:FindFirstChild("KeybindHintText")
    if hintLabel then
        hintLabel:Destroy()
    end

    local hintImage = instance:FindFirstChild("KeybindHintImage")
    if hintImage then
        hintImage:Destroy()
    end
end)

local module = {}

function module.TryUpdateKeybind(name: string): ()
    if not boundInstances[name] then
        return
    end

    for _, v in boundInstances[name] do
        updateText(name, v)
    end
end

ControlManager.PreferredInput:Connect(function()
    for name in boundInstances do
        module.TryUpdateKeybind(name)
    end
end)

return table.freeze(module)
