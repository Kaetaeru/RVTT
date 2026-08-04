--!strict

local function deepCopy(value: unknown, seen: { [table]: table }?): unknown
	if type(value) ~= "table" then
		return value
	end
	local visited = seen or {}
	local source = value :: table
	if visited[source] ~= nil then
		return visited[source]
	end
	local target = {}
	visited[source] = target
	for key, child in source do
		target[deepCopy(key, visited)] = deepCopy(child, visited)
	end
	return target
end

return deepCopy
