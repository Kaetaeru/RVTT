--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)

local ContentDefinitionResolver = {}

local function sortedKeys(source: any): { string }
	local keys = {}
	if type(source) == "table" then
		for key in source do
			if type(key) == "string" then
				table.insert(keys, key)
			end
		end
	end
	table.sort(keys)
	return keys
end

function ContentDefinitionResolver.resolve(
	domains: any,
	collectionName: string,
	definitionId: string
): any?
	local content = domains.content
	local packs = if type(content) == "table" then content.packs else nil
	local active = if type(content) == "table" then content.active else nil
	if type(packs) ~= "table" or type(active) ~= "table" then
		return nil
	end
	for _, packId in sortedKeys(active) do
		local pack = packs[packId]
		if type(pack) == "table" and active[packId] == pack.version then
			local definitions = pack.definitions
			local collection = if type(definitions) == "table"
				then definitions[collectionName]
				else nil
			local definition = if type(collection) == "table" then collection[definitionId] else nil
			if type(definition) == "table" then
				return DeepCopy(definition)
			end
		end
	end
	return nil
end

return table.freeze(ContentDefinitionResolver)
