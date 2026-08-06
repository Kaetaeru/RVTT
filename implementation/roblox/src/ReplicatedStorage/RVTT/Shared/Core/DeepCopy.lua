--!strict

type AnyTable = { [any]: any }

local function deepCopy<T>(value: T, seen: { [AnyTable]: AnyTable }?): T
	if type(value) ~= "table" then
		return value
	end

	local visited = seen or {}
	local source = value :: AnyTable
	local previous = visited[source]
	if previous ~= nil then
		return previous :: any
	end

	local target: AnyTable = {}
	visited[source] = target
	for key, child in source do
		target[deepCopy(key, visited)] = deepCopy(child, visited)
	end
	return target :: any
end

return deepCopy
