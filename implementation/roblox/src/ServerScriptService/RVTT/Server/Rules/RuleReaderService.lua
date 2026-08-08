--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RuleLink = require(ReplicatedStorage.RVTT.Shared.Rules.RuleLink)

local RuleReaderService = {}

local MAX_SEARCH_RESULTS = 20
local MAX_SNIPPET_CHARS = 180

local function roleAllowed(entry: any, viewer: any): boolean
	if type(entry) ~= "table" then
		return false
	end
	local visibility = entry.visibility
	if visibility == nil or visibility == "public" then
		return true
	end
	if visibility == "dm" then
		return viewer.role == "dm"
	end
	if type(entry.allowedRoles) == "table" then
		for _, role in entry.allowedRoles do
			if role == viewer.role then
				return true
			end
		end
	end
	if type(entry.allowedUserIds) == "table" then
		for _, userId in entry.allowedUserIds do
			if userId == viewer.userId then
				return true
			end
		end
	end
	return false
end

local function findModule(package: any, moduleId: string): any?
	for _, module in package.modules or {} do
		if module.id == moduleId then
			return module
		end
	end
	return nil
end

local function findDocument(module: any, documentId: string): any?
	for _, document in module.documents or {} do
		if document.id == documentId then
			return document
		end
	end
	return nil
end

local function findSection(document: any, anchorId: string?): any?
	local sections = document.sections or {}
	if anchorId == nil then
		return sections[1]
	end
	for _, section in sections do
		if section.anchorId == anchorId then
			return section
		end
	end
	return nil
end

local function visibleDocument(module: any, document: any, viewer: any): boolean
	return roleAllowed(module, viewer) and roleAllowed(document, viewer)
end

local function safeUri(
	packageId: string,
	moduleId: string,
	documentId: string,
	anchorId: string?
): string?
	return RuleLink.build(packageId, moduleId, documentId, anchorId)
end

local function publicSection(
	packageId: string,
	moduleId: string,
	documentId: string,
	section: any
): any
	return {
		anchorId = section.anchorId,
		title = section.title,
		uri = safeUri(packageId, moduleId, documentId, section.anchorId),
	}
end

local function publicDocument(packageId: string, moduleId: string, document: any): any
	local sections = {}
	for _, section in document.sections or {} do
		table.insert(sections, publicSection(packageId, moduleId, document.id, section))
	end
	return {
		id = document.id,
		title = document.title,
		sourceLabel = document.sourceLabel,
		uri = safeUri(packageId, moduleId, document.id, nil),
		sections = sections,
	}
end

local function chunkIndex(package: any, chunkId: string): (any?, any?, any?)
	local chunk = if type(package.chunks) == "table" then package.chunks[chunkId] else nil
	if type(chunk) ~= "table" then
		return nil, nil, nil
	end
	local module = findModule(package, chunk.moduleId)
	if module == nil then
		return nil, nil, nil
	end
	local document = findDocument(module, chunk.documentId)
	if document == nil then
		return nil, nil, nil
	end
	return chunk, module, document
end

local function adjacentChunkIds(document: any, targetId: string): (string?, string?)
	local ordered = {}
	for _, section in document.sections or {} do
		for _, chunkId in section.chunkIds or {} do
			table.insert(ordered, chunkId)
		end
	end
	for index, chunkId in ordered do
		if chunkId == targetId then
			return ordered[index - 1], ordered[index + 1]
		end
	end
	return nil, nil
end

local function filteredLinks(package: any, viewer: any, links: any): { string }
	local result = {}
	for _, uri in links or {} do
		local parsed = RuleLink.parse(uri)
		if parsed ~= nil and parsed.packageId == package.packageId then
			local module = findModule(package, parsed.moduleId)
			local document = if module ~= nil then findDocument(module, parsed.documentId) else nil
			if module ~= nil and document ~= nil and visibleDocument(module, document, viewer) then
				table.insert(result, uri)
			end
		end
	end
	return result
end

local function safeChunk(package: any, viewer: any, chunk: any, document: any): any
	local previousChunkId, nextChunkId = adjacentChunkIds(document, chunk.id)
	return {
		id = chunk.id,
		text = chunk.text,
		anchorId = chunk.anchorId,
		uri = safeUri(package.packageId, chunk.moduleId, chunk.documentId, chunk.anchorId),
		previousChunkId = previousChunkId,
		nextChunkId = nextChunkId,
		relatedLinks = filteredLinks(package, viewer, chunk.relatedLinks),
		backlinks = filteredLinks(package, viewer, chunk.backlinks),
	}
end

local function normalizedQuery(value: any): string
	if type(value) ~= "string" then
		return ""
	end
	local trimmed = string.gsub(value, "^%s*(.-)%s*$", "%1")
	return string.lower(trimmed)
end

local function snippet(text: string, query: string): string
	local lower = string.lower(text)
	local startAt = if query ~= "" then string.find(lower, query, 1, true) else nil
	local startIndex = math.max(1, (startAt or 1) - 48)
	local finishIndex = math.min(#text, startIndex + MAX_SNIPPET_CHARS - 1)
	local value = string.sub(text, startIndex, finishIndex)
	if startIndex > 1 then
		value = "…" .. value
	end
	if finishIndex < #text then
		value ..= "…"
	end
	return value
end

function RuleReaderService.manifest(package: any, viewer: any, profileStatus: any): any
	local modules = {}
	for _, module in package.modules or {} do
		if roleAllowed(module, viewer) then
			local documents = {}
			for _, document in module.documents or {} do
				if visibleDocument(module, document, viewer) then
					table.insert(documents, publicDocument(package.packageId, module.id, document))
				end
			end
			if #documents > 0 then
				table.insert(modules, {
					id = module.id,
					title = module.title,
					documents = documents,
				})
			end
		end
	end
	return {
		collection = { id = "core-rules", title = "Core Rules" },
		packageId = package.packageId,
		version = package.version,
		locale = package.locale,
		license = package.license,
		profile = profileStatus,
		modules = modules,
	}
end

function RuleReaderService.search(package: any, viewer: any, queryValue: any, limitValue: any): any
	local query = normalizedQuery(queryValue)
	if query == "" then
		return { query = "", results = {} }
	end
	local limit = if type(limitValue) == "number" and limitValue % 1 == 0
		then math.clamp(limitValue, 1, MAX_SEARCH_RESULTS)
		else 12
	local results = {}
	for _, module in package.modules or {} do
		if roleAllowed(module, viewer) then
			for _, document in module.documents or {} do
				if visibleDocument(module, document, viewer) then
					for _, section in document.sections or {} do
						for _, chunkId in section.chunkIds or {} do
							local chunk = package.chunks[chunkId]
							if type(chunk) == "table" then
								local haystack = string.lower(
									tostring(document.title)
										.. " "
										.. tostring(section.title)
										.. " "
										.. tostring(chunk.text)
										.. " "
										.. table.concat(chunk.keywords or {}, " ")
								)
								if string.find(haystack, query, 1, true) ~= nil then
									table.insert(results, {
										moduleTitle = module.title,
										documentTitle = document.title,
										sectionTitle = section.title,
										uri = safeUri(
											package.packageId,
											module.id,
											document.id,
											section.anchorId
										),
										snippet = snippet(chunk.text, query),
									})
									if #results >= limit then
										return { query = queryValue, results = results }
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return { query = queryValue, results = results }
end

function RuleReaderService.open(package: any, viewer: any, uri: any): (any?, string?)
	local parsed = RuleLink.parse(uri)
	if parsed == nil or parsed.packageId ~= package.packageId then
		return nil, "RULE_LINK_UNAVAILABLE"
	end
	local module = findModule(package, parsed.moduleId)
	local document = if module ~= nil then findDocument(module, parsed.documentId) else nil
	if module == nil or document == nil or not visibleDocument(module, document, viewer) then
		return nil, "RULE_LINK_UNAVAILABLE"
	end
	local section = findSection(document, parsed.anchorId)
	if section == nil or type(section.chunkIds) ~= "table" or section.chunkIds[1] == nil then
		return nil, "RULE_SECTION_UNAVAILABLE"
	end
	local chunk = package.chunks[section.chunkIds[1]]
	if type(chunk) ~= "table" then
		return nil, "RULE_CHUNK_UNAVAILABLE"
	end
	return {
		module = { id = module.id, title = module.title },
		document = publicDocument(package.packageId, module.id, document),
		section = publicSection(package.packageId, module.id, document.id, section),
		chunk = safeChunk(package, viewer, chunk, document),
	},
		nil
end

function RuleReaderService.chunk(package: any, viewer: any, chunkId: any): (any?, string?)
	if type(chunkId) ~= "string" then
		return nil, "RULE_CHUNK_UNAVAILABLE"
	end
	local chunk, module, document = chunkIndex(package, chunkId)
	if
		chunk == nil
		or module == nil
		or document == nil
		or not visibleDocument(module, document, viewer)
	then
		return nil, "RULE_CHUNK_UNAVAILABLE"
	end
	return safeChunk(package, viewer, chunk, document), nil
end

return table.freeze(RuleReaderService)
