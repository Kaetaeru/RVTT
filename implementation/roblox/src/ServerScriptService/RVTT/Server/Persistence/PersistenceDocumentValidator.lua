--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ValueGuard = require(ReplicatedStorage.RVTT.Shared.Core.ValueGuard)

local PersistenceDocumentValidator = {}

type ActiveTables = { [any]: boolean }

local function childPath(path: string, key: any): string
	if type(key) == "number" then
		return string.format("%s[%d]", path, key)
	end
	return string.format("%s.%s", path, tostring(key))
end

local function validUtf8(value: string): boolean
	return utf8.len(value) ~= nil
end

local function validateValue(value: any, path: string, active: ActiveTables): (boolean, string?)
	local valueType = typeof(value)
	if valueType == "nil" or valueType == "boolean" then
		return true, nil
	end
	if valueType == "number" then
		if ValueGuard.isFiniteNumber(value) then
			return true, nil
		end
		return false, path .. " contains a non-finite number"
	end
	if valueType == "string" then
		if validUtf8(value) then
			return true, nil
		end
		return false, path .. " contains invalid UTF-8"
	end
	if valueType ~= "table" then
		return false, string.format("%s contains unsupported type %s", path, valueType)
	end

	if active[value] then
		return false, path .. " contains a cyclic table reference"
	end
	active[value] = true

	local hasStringKeys = false
	local hasNumericKeys = false
	local numericKeyCount = 0
	local maximumNumericKey = 0

	for key in value do
		local keyType = typeof(key)
		if keyType == "string" then
			if not validUtf8(key) then
				active[value] = nil
				return false, path .. " contains an invalid UTF-8 key"
			end
			hasStringKeys = true
		elseif
			keyType == "number"
			and ValueGuard.isFiniteNumber(key)
			and key >= 1
			and key % 1 == 0
		then
			hasNumericKeys = true
			numericKeyCount += 1
			maximumNumericKey = math.max(maximumNumericKey, key)
		else
			active[value] = nil
			return false, string.format("%s contains unsupported table key %s", path, tostring(key))
		end
	end

	if hasStringKeys and hasNumericKeys then
		active[value] = nil
		return false, path .. " mixes dictionary and array keys"
	end
	if hasNumericKeys and maximumNumericKey ~= numericKeyCount then
		active[value] = nil
		return false, path .. " contains a sparse array"
	end

	for key, child in value do
		local ok, reason = validateValue(child, childPath(path, key), active)
		if not ok then
			active[value] = nil
			return false, reason
		end
	end

	active[value] = nil
	return true, nil
end

function PersistenceDocumentValidator.validate(value: any): (boolean, string?)
	return validateValue(value, "$", {})
end

return table.freeze(PersistenceDocumentValidator)
