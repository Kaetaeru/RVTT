--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)
local PreferenceSchema = require(ReplicatedStorage.RVTT.Shared.UI.PreferenceSchema)

export type Store = {
	Changed: any,
	get: (self: Store, key: string) -> any,
	snapshot: (self: Store) -> { [string]: any },
	set: (self: Store, key: string, value: any) -> (boolean, any, string?),
	reset: (self: Store, key: string) -> (boolean, any, string?),
	resetAll: (self: Store) -> (),
	destroy: (self: Store) -> (),
}

local Store = {}
Store.__index = Store

function Store.new(initial: any?): Store
	local values = PreferenceSchema.defaults()
	if type(initial) == "table" then
		for key, value in initial do
			local valid, normalized = PreferenceSchema.normalize(key, value)
			if valid then
				values[key] = normalized
			end
		end
	end
	return setmetatable({
		_values = values,
		Changed = Signal.new(),
	}, Store) :: any
end

function Store.get(self: any, key: string): any
	if not PreferenceSchema.isKnown(key) then
		return nil
	end
	return DeepCopy(self._values[key])
end

function Store.snapshot(self: any): { [string]: any }
	return DeepCopy(self._values)
end

function Store.set(self: any, key: string, value: any): (boolean, any, string?)
	local valid, normalized, errorCode = PreferenceSchema.normalize(key, value)
	if not valid then
		return false, nil, errorCode
	end
	self._values[key] = DeepCopy(normalized)
	self.Changed:Fire(key, DeepCopy(normalized), self:snapshot())
	return true, DeepCopy(normalized), nil
end

function Store.reset(self: any, key: string): (boolean, any, string?)
	local defaultValue = PreferenceSchema.defaultFor(key)
	if defaultValue == nil then
		return false, nil, "UNKNOWN_PREFERENCE"
	end
	self._values[key] = defaultValue
	self.Changed:Fire(key, DeepCopy(defaultValue), self:snapshot())
	return true, DeepCopy(defaultValue), nil
end

function Store.resetAll(self: any)
	self._values = PreferenceSchema.defaults()
	self.Changed:Fire("*", nil, self:snapshot())
end

function Store.destroy(self: any)
	self.Changed:Destroy()
end

return Store
