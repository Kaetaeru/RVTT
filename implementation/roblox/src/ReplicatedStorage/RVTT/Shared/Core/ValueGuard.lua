--!strict

local ValueGuard = {}

export type Limits = {
	maxDepth: number,
	maxNodes: number,
	maxStringBytes: number,
	maxArrayLength: number,
}

local DEFAULT_LIMITS: Limits = {
	maxDepth = 8,
	maxNodes = 512,
	maxStringBytes = 4096,
	maxArrayLength = 256,
}

local function inspect(
	value: unknown,
	limits: Limits,
	depth: number,
	counter: { count: number },
	seen: { [table]: boolean }
): boolean
	counter.count += 1
	if counter.count > limits.maxNodes or depth > limits.maxDepth then
		return false
	end

	local valueType = type(value)
	if valueType == "nil" or valueType == "boolean" then
		return true
	end
	if valueType == "number" then
		local numberValue = value :: number
		return numberValue == numberValue and numberValue > -math.huge and numberValue < math.huge
	end
	if valueType == "string" then
		return #(value :: string) <= limits.maxStringBytes
	end
	if valueType ~= "table" then
		return false
	end

	local tableValue = value :: table
	if seen[tableValue] then
		return false
	end
	seen[tableValue] = true

	local arrayCount = 0
	for key, child in tableValue do
		local keyType = type(key)
		if keyType ~= "string" and keyType ~= "number" then
			seen[tableValue] = nil
			return false
		end
		if keyType == "number" then
			arrayCount += 1
			if arrayCount > limits.maxArrayLength then
				seen[tableValue] = nil
				return false
			end
		elseif #(key :: string) > 128 then
			seen[tableValue] = nil
			return false
		end
		if not inspect(child, limits, depth + 1, counter, seen) then
			seen[tableValue] = nil
			return false
		end
	end

	seen[tableValue] = nil
	return true
end

function ValueGuard.isSerializable(value: unknown, limits: Limits?): boolean
	return inspect(value, limits or DEFAULT_LIMITS, 0, { count = 0 }, {})
end

function ValueGuard.isFiniteNumber(value: unknown): boolean
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function ValueGuard.isBoundedString(value: unknown, maximum: number): boolean
	return type(value) == "string" and #value > 0 and #value <= maximum
end

function ValueGuard.isVector3Record(value: unknown, absoluteLimit: number): boolean
	if type(value) ~= "table" then
		return false
	end
	local record = value :: { [string]: unknown }
	for _, axis in { "x", "y", "z" } do
		local component = record[axis]
		if
			not ValueGuard.isFiniteNumber(component)
			or math.abs(component :: number) > absoluteLimit
		then
			return false
		end
	end
	return true
end

return table.freeze(ValueGuard)
