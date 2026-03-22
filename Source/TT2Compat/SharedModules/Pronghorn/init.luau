
local module = {}

module.DeferredComplete = {
	Get = function() return true end,
	Wait = function() return true end,
}

return table.freeze(module)