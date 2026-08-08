--!strict

local AccentPreference = require(script.Parent.AccentPreference)
local DeepCopy = require(script.Parent.Parent.Core.DeepCopy)

export type Preferences = { [string]: any }

local defaults: Preferences = {
	accentPaletteId = AccentPreference.DEFAULT_ID,
	uiScale = 1,
	textScale = 1,
	actionMatrixRows = 2,
	tooltipDelay = 0.25,
	detailedTooltipDelay = 0.75,
	disabledReasonDelay = 0.15,
	motion = "full",
	bindings = {},
}

local function clampedNumber(value: any, minimum: number, maximum: number): (boolean, any)
	if type(value) ~= "number" or value ~= value then
		return false, nil
	end
	return true, math.clamp(value, minimum, maximum)
end

local function clampedInteger(value: any, minimum: number, maximum: number): (boolean, any)
	local valid, normalized = clampedNumber(value, minimum, maximum)
	if not valid then
		return false, nil
	end
	return true, math.floor(normalized + 0.5)
end

local function enum(value: any, allowed: { [string]: boolean }): (boolean, any)
	if type(value) ~= "string" or allowed[value] ~= true then
		return false, nil
	end
	return true, value
end

local function bindings(value: any): (boolean, any)
	if type(value) ~= "table" then
		return false, nil
	end
	local normalized: { [string]: string } = {}
	for actionId, bindingId in value do
		if
			type(actionId) ~= "string"
			or actionId == ""
			or #actionId > 96
			or type(bindingId) ~= "string"
			or bindingId == ""
			or #bindingId > 96
		then
			return false, nil
		end
		normalized[actionId] = bindingId
	end
	return true, normalized
end

local normalizers: { [string]: (any) -> (boolean, any) } = {
	accentPaletteId = function(value)
		if not AccentPreference.isValid(value) then
			return false, nil
		end
		return true, value
	end,
	uiScale = function(value)
		return clampedNumber(value, 0.8, 1.4)
	end,
	textScale = function(value)
		return clampedNumber(value, 0.9, 1.3)
	end,
	actionMatrixRows = function(value)
		return clampedInteger(value, 1, 4)
	end,
	tooltipDelay = function(value)
		return clampedNumber(value, 0, 2)
	end,
	detailedTooltipDelay = function(value)
		return clampedNumber(value, 0, 3)
	end,
	disabledReasonDelay = function(value)
		return clampedNumber(value, 0, 2)
	end,
	motion = function(value)
		return enum(value, { full = true, reduced = true, minimal = true })
	end,
	bindings = bindings,
}

local PreferenceSchema = {}

function PreferenceSchema.isKnown(key: any): boolean
	return type(key) == "string" and normalizers[key] ~= nil
end

function PreferenceSchema.normalize(key: any, value: any): (boolean, any, string?)
	if type(key) ~= "string" then
		return false, nil, "UNKNOWN_PREFERENCE"
	end
	local normalizer = normalizers[key]
	if normalizer == nil then
		return false, nil, "UNKNOWN_PREFERENCE"
	end
	local valid, normalized = normalizer(value)
	if not valid then
		return false, nil, "INVALID_PREFERENCE_VALUE"
	end
	return true, normalized, nil
end

function PreferenceSchema.defaultFor(key: any): any
	if not PreferenceSchema.isKnown(key) then
		return nil
	end
	return DeepCopy(defaults[key])
end

function PreferenceSchema.defaults(): Preferences
	return DeepCopy(defaults)
end

return table.freeze(PreferenceSchema)

