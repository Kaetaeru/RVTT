--!strict

local Signal = require(script.Parent.Parent.Core.Signal)

local Host = {}
Host.__index = Host

local function copy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in value do
		result[key] = copy(child)
	end
	return result
end

local function clamp(value: number, minimum: number, maximum: number): number
	return math.max(minimum, math.min(maximum, value))
end

function Host.new(registry: any): any
	return setmetatable({
		registry = registry,
		windowsByInstanceId = {},
		zOrder = {},
		tabGroups = {},
		focusedInstanceId = nil,
		layoutRevision = 0,
		nextInstanceNumber = 0,
		Changed = Signal.new(),
	}, Host)
end

function Host:_changed(reason: string, instanceId: string?)
	self.layoutRevision += 1
	self.Changed:Fire(reason, instanceId, self:snapshot())
end

function Host:_focusWithoutSignal(instanceId: string)
	for index, id in self.zOrder do
		if id == instanceId then
			table.remove(self.zOrder, index)
			break
		end
	end
	table.insert(self.zOrder, instanceId)
	self.focusedInstanceId = instanceId
end

function Host:open(moduleId: string, contextKey: string?): (any?, boolean)
	local definition = self.registry:get(moduleId)
	if definition == nil or definition.instancePolicy == "context_popover" then
		return nil, false
	end
	if definition.instancePolicy == "singleton" then
		for _, instanceId in self.zOrder do
			local existing = self.windowsByInstanceId[instanceId]
			if existing ~= nil and existing.moduleId == moduleId then
				existing.minimized = false
				self:_focusWithoutSignal(instanceId)
				self:_changed("focus_existing", instanceId)
				return existing, false
			end
		end
	end
	if definition.instancePolicy == "per_entity" and type(contextKey) ~= "string" then
		return nil, false
	end
	if definition.instancePolicy == "per_entity" or definition.instancePolicy == "per_document" then
		for _, existing in self.windowsByInstanceId do
			if existing.moduleId == moduleId and existing.contextKey == contextKey then
				self:_focusWithoutSignal(existing.instanceId)
				self:_changed("focus_existing", existing.instanceId)
				return existing, false
			end
		end
	end

	self.nextInstanceNumber += 1
	local instanceId = string.format("%s:%d", moduleId, self.nextInstanceNumber)
	local placement = definition.defaultWindowPlacement or {}
	local minimumSize = definition.minimumSize or { x = 260, y = 180 }
	local maximumSize = definition.maximumSize or { x = 900, y = 760 }
	local window = {
		instanceId = instanceId,
		moduleId = moduleId,
		contextKey = contextKey,
		projectionRevision = -1,
		localViewState = {},
		lifecycleState = "visible",
		position = copy(placement.position or { x = 32, y = 72 }),
		size = copy(placement.size or minimumSize),
		minimumSize = copy(minimumSize),
		maximumSize = copy(maximumSize),
		dock = placement.dock,
		minimized = false,
	}
	self.windowsByInstanceId[instanceId] = window
	self:_focusWithoutSignal(instanceId)
	self:_changed("opened", instanceId)
	return window, true
end

function Host:focus(instanceId: string): boolean
	if self.windowsByInstanceId[instanceId] == nil then
		return false
	end
	self:_focusWithoutSignal(instanceId)
	self:_changed("focused", instanceId)
	return true
end

function Host:move(instanceId: string, x: number, y: number): boolean
	local window = self.windowsByInstanceId[instanceId]
	if window == nil then
		return false
	end
	window.position = { x = x, y = y }
	window.dock = nil
	self:_changed("moved", instanceId)
	return true
end

function Host:resize(instanceId: string, x: number, y: number): boolean
	local window = self.windowsByInstanceId[instanceId]
	if window == nil then
		return false
	end
	window.size = {
		x = clamp(x, window.minimumSize.x, window.maximumSize.x),
		y = clamp(y, window.minimumSize.y, window.maximumSize.y),
	}
	self:_changed("resized", instanceId)
	return true
end

function Host:minimize(instanceId: string): boolean
	local window = self.windowsByInstanceId[instanceId]
	if window == nil then
		return false
	end
	window.minimized = true
	window.lifecycleState = "minimized"
	self:_changed("minimized", instanceId)
	return true
end

function Host:restore(instanceId: string): boolean
	local window = self.windowsByInstanceId[instanceId]
	if window == nil then
		return false
	end
	window.minimized = false
	window.lifecycleState = "visible"
	self:_focusWithoutSignal(instanceId)
	self:_changed("restored", instanceId)
	return true
end

function Host:dock(instanceId: string, side: string): boolean
	if side ~= "left" and side ~= "right" and side ~= "bottom" then
		return false
	end
	local window = self.windowsByInstanceId[instanceId]
	if window == nil then
		return false
	end
	window.dock = side
	self:_changed("docked", instanceId)
	return true
end

function Host:undock(instanceId: string): boolean
	local window = self.windowsByInstanceId[instanceId]
	if window == nil then
		return false
	end
	window.dock = nil
	self:_changed("undocked", instanceId)
	return true
end

function Host:groupTabs(instanceIds: { string }): boolean
	if #instanceIds < 2 then
		return false
	end
	for _, instanceId in instanceIds do
		if self.windowsByInstanceId[instanceId] == nil then
			return false
		end
	end
	local groupId = "tab:" .. table.concat(instanceIds, ":")
	self.tabGroups[groupId] = table.clone(instanceIds)
	self:_changed("tab_grouped", instanceIds[1])
	return true
end

function Host:close(instanceId: string): boolean
	local window = self.windowsByInstanceId[instanceId]
	if window == nil then
		return false
	end
	window.lifecycleState = "disposed"
	self.windowsByInstanceId[instanceId] = nil
	for index, id in self.zOrder do
		if id == instanceId then
			table.remove(self.zOrder, index)
			break
		end
	end
	self.focusedInstanceId = self.zOrder[#self.zOrder]
	for groupId, members in self.tabGroups do
		local retained = {}
		for _, memberId in members do
			if memberId ~= instanceId then
				table.insert(retained, memberId)
			end
		end
		self.tabGroups[groupId] = if #retained > 1 then retained else nil
	end
	self:_changed("closed", instanceId)
	return true
end

function Host:purgeSensitive()
	local ids = table.clone(self.zOrder)
	for _, instanceId in ids do
		self:close(instanceId)
	end
end

function Host:snapshot(): any
	return {
		windowsByInstanceId = copy(self.windowsByInstanceId),
		zOrder = table.clone(self.zOrder),
		tabGroups = copy(self.tabGroups),
		focusedInstanceId = self.focusedInstanceId,
		layoutRevision = self.layoutRevision,
	}
end

function Host:serializeLayout(): any
	local windows = {}
	for instanceId, window in self.windowsByInstanceId do
		windows[instanceId] = {
			instanceId = instanceId,
			moduleId = window.moduleId,
			contextKey = window.contextKey,
			position = copy(window.position),
			size = copy(window.size),
			dock = window.dock,
			minimized = window.minimized,
		}
	end
	return {
		windowsByInstanceId = windows,
		zOrder = table.clone(self.zOrder),
		tabGroups = copy(self.tabGroups),
		focusedInstanceId = self.focusedInstanceId,
		layoutRevision = self.layoutRevision,
	}
end

function Host:restoreLayout(layout: any): boolean
	if
		type(layout) ~= "table"
		or type(layout.windowsByInstanceId) ~= "table"
		or type(layout.zOrder) ~= "table"
	then
		return false
	end
	local windows = {}
	local order = {}
	for _, instanceId in layout.zOrder do
		local saved = layout.windowsByInstanceId[instanceId]
		local definition = if type(saved) == "table" then self.registry:get(saved.moduleId) else nil
		if definition ~= nil and definition.instancePolicy ~= "context_popover" then
			local minimumSize = definition.minimumSize or { x = 260, y = 180 }
			local maximumSize = definition.maximumSize or { x = 900, y = 760 }
			local size = if type(saved.size) == "table" then saved.size else minimumSize
			local position = if type(saved.position) == "table"
				then saved.position
				else { x = 32, y = 72 }
			windows[instanceId] = {
				instanceId = instanceId,
				moduleId = saved.moduleId,
				contextKey = saved.contextKey,
				projectionRevision = -1,
				localViewState = {},
				lifecycleState = if saved.minimized == true then "minimized" else "visible",
				position = { x = tonumber(position.x) or 32, y = tonumber(position.y) or 72 },
				size = {
					x = clamp(tonumber(size.x) or minimumSize.x, minimumSize.x, maximumSize.x),
					y = clamp(tonumber(size.y) or minimumSize.y, minimumSize.y, maximumSize.y),
				},
				minimumSize = copy(minimumSize),
				maximumSize = copy(maximumSize),
				dock = if saved.dock == "left"
						or saved.dock == "right"
						or saved.dock == "bottom"
					then saved.dock
					else nil,
				minimized = saved.minimized == true,
			}
			table.insert(order, instanceId)
		end
	end
	self.windowsByInstanceId = windows
	self.zOrder = order
	self.tabGroups = if type(layout.tabGroups) == "table" then copy(layout.tabGroups) else {}
	self.focusedInstanceId = if type(layout.focusedInstanceId) == "string"
			and windows[layout.focusedInstanceId] ~= nil
		then layout.focusedInstanceId
		else order[#order]
	self:_changed("layout_restored", self.focusedInstanceId)
	return true
end

function Host:destroy()
	self:purgeSensitive()
	self.Changed:Destroy()
end

return Host
