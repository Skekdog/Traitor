local DynamicValue = require(script.Parent.DynamicValue)

local module = {}

function module.ListenProperty<T>(instance: Instance, property: string, _: T): DynamicValue.DynamicValue<T>
	local value = DynamicValue.new((instance :: any)[property])

	instance:GetPropertyChangedSignal(property):Connect(function()
		value:SetValue((instance :: any)[property])
	end)

	return value
end

function module.ListenAttribute<T>(instance: Instance, attribute: string, _: T): DynamicValue.DynamicValue<T>
	local value = DynamicValue.new(instance:GetAttribute(attribute) :: T)

	instance:GetAttributeChangedSignal(attribute):Connect(function()
		value:SetValue(instance:GetAttribute(attribute) :: T)
	end)

	return value
end

return module