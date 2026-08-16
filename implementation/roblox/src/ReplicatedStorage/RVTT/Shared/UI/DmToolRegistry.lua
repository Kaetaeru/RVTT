--!strict

local ALLOWED_POLICIES = {
	singleton = true,
	per_entity = true,
	per_document = true,
	multiple = true,
	context_popover = true,
}

local ALLOWED_COMMANDS = {
	["dm.assign_control"] = true,
	["dm.quick_action"] = true,
	["dm.runtime_patch"] = true,
	["dm.request_recovery"] = true,
}

local Registry = {}
Registry.__index = Registry

function Registry.new(): any
	return setmetatable({ byId = {}, order = {} }, Registry)
end

function Registry:register(definition: any)
	assert(type(definition) == "table", "DM tool definition must be a table")
	assert(type(definition.moduleId) == "string" and definition.moduleId ~= "", "moduleId required")
	assert(self.byId[definition.moduleId] == nil, "duplicate DM tool moduleId")
	assert(ALLOWED_POLICIES[definition.instancePolicy] == true, "invalid instance policy")
	assert(type(definition.title) == "string", "title required")
	for _, commandType in definition.commandBindings or {} do
		assert(ALLOWED_COMMANDS[commandType] == true, "unknown DM authority command")
	end
	self.byId[definition.moduleId] = table.clone(definition)
	table.insert(self.order, definition.moduleId)
end

function Registry:get(moduleId: string): any?
	return self.byId[moduleId]
end

function Registry:list(): { any }
	local result = {}
	for _, moduleId in self.order do
		table.insert(result, self.byId[moduleId])
	end
	return result
end

return Registry
