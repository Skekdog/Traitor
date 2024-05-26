local store = Instance.new("Folder")
store.Name = "ClientStorage"
store.Parent = game

local scriptConnections = Instance.new("Folder")
scriptConnections.Name = "ScriptConnections"

local function makeEvent(name: string, isFunction: boolean?): BindableEvent | BindableFunction
	local suffix: string
	local event: any
	if isFunction then
		event = Instance.new("BindableFunction")
		suffix = "Function"
	else
		event = Instance.new("BindableEvent")
		suffix = "Event"
	end
	event.Name = name..suffix
	event.Parent = scriptConnections
	return event
end

makeEvent("Equip")--send signal that something was equipped
makeEvent("RemoteEquip")--force an equip state from client
makeEvent("InventoryChanged")--item added or removed from inv
makeEvent("PingRadar")

makeEvent("Reload")
makeEvent("Fire")
makeEvent("ADS")

makeEvent("ShowCorpse")

makeEvent("JoinRound")

local currentMapObject = Instance.new("ObjectValue")
currentMapObject.Name = "CurrentMapObject"
currentMapObject.Parent = store

store:SetAttribute("IsSpectating", true)
store:SetAttribute("RoundStartTime", 0)

scriptConnections.Parent = store