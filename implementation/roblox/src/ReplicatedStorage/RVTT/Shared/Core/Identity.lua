--!strict

local HttpService = game:GetService("HttpService")

local Identity = {}

local VALID_PREFIX = "^[a-z][a-z0-9_%-]*$"

function Identity.isValidPrefix(prefix: string): boolean
	return string.match(prefix, VALID_PREFIX) ~= nil
end

function Identity.new(prefix: string, raw: string?): string
	assert(Identity.isValidPrefix(prefix), "invalid identity prefix")
	local value = raw or HttpService:GenerateGUID(false)
	assert(#value > 0 and #value <= 128, "invalid identity value")
	return prefix .. ":" .. value
end

function Identity.is(value: unknown, prefix: string?): boolean
	if type(value) ~= "string" or #value < 3 or #value > 160 then
		return false
	end
	local separator = string.find(value, ":", 1, true)
	if separator == nil then
		return false
	end
	if prefix ~= nil then
		return string.sub(value, 1, separator - 1) == prefix
	end
	return true
end

return table.freeze(Identity)
