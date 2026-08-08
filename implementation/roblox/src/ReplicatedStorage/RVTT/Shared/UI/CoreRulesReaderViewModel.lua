--!strict

local CoreRulesReaderViewModel = {}

local ERROR_LABELS = {
	PRIVATE_SOURCE_MISSING = "비공개 규칙 Source를 찾을 수 없습니다",
	SOURCE_BINDING_MISMATCH = "규칙 Source binding이 일치하지 않습니다",
	SOURCE_REVISION_MISMATCH = "규칙 Source revision이 일치하지 않습니다",
	SOURCE_ROOT_MISMATCH = "규칙 Source root가 일치하지 않습니다",
	CONTENT_COUNT_MISMATCH = "규칙 Content count가 일치하지 않습니다",
	SOURCE_DIGEST_MISMATCH = "규칙 Source digest가 일치하지 않습니다",
	RULE_PACKAGE_UNAVAILABLE = "규칙 Package를 사용할 수 없습니다",
	RULE_LINK_UNAVAILABLE = "이 Rule Link를 현재 권한으로 열 수 없습니다",
	RULE_SECTION_UNAVAILABLE = "Rule Section을 사용할 수 없습니다",
	RULE_CHUNK_UNAVAILABLE = "Rule Chunk를 사용할 수 없습니다",
	RATE_LIMITED = "요청이 너무 빠릅니다. 잠시 후 다시 시도하세요",
	TRANSPORT_ERROR = "규칙 서버에 연결할 수 없습니다",
}

function CoreRulesReaderViewModel.initial(): any
	return {
		status = "idle",
		manifest = nil,
		searchQuery = "",
		searchResults = {},
		openDocument = nil,
		openSection = nil,
		chunks = {},
		chunkOrder = {},
		activeUri = nil,
		errorCode = nil,
	}
end

function CoreRulesReaderViewModel.errorLabel(code: any): string
	if type(code) == "string" and ERROR_LABELS[code] ~= nil then
		return ERROR_LABELS[code]
	end
	return "규칙 데이터를 불러올 수 없습니다"
end

function CoreRulesReaderViewModel.profileBadge(manifest: any): string
	local profile = if type(manifest) == "table" then manifest.profile else nil
	if type(profile) ~= "table" then
		return "RULE PROFILE —"
	end
	if profile.fallbackActive == true then
		return "SRD FALLBACK"
	end
	local basePackageId = profile.basePackageId
	if basePackageId == "rvtt.test.rules.2024.integrated.ko" then
		return "INTEGRATED TEST"
	end
	if basePackageId == "rvtt.core.rules" then
		return "SRD RELEASE"
	end
	return "RULE PROFILE"
end

function CoreRulesReaderViewModel.firstUri(manifest: any): string?
	if type(manifest) ~= "table" or type(manifest.modules) ~= "table" then
		return nil
	end
	for _, module in manifest.modules do
		for _, document in module.documents or {} do
			local section = if type(document.sections) == "table" then document.sections[1] else nil
			if type(section) == "table" and type(section.uri) == "string" then
				return section.uri
			end
			if type(document.uri) == "string" then
				return document.uri
			end
		end
	end
	return nil
end

function CoreRulesReaderViewModel.applyManifest(state: any, result: any): any
	if type(result) ~= "table" or result.ok ~= true or type(result.value) ~= "table" then
		state.status = "error"
		state.errorCode = if type(result) == "table" and type(result.error) == "table"
			then result.error.code
			else "INVALID_RESPONSE"
		return state
	end
	state.status = "ready"
	state.manifest = result.value
	state.errorCode = nil
	return state
end

function CoreRulesReaderViewModel.applySearch(state: any, query: string, result: any): any
	state.searchQuery = query
	if type(result) ~= "table" or result.ok ~= true or type(result.value) ~= "table" then
		state.status = "error"
		state.errorCode = if type(result) == "table" and type(result.error) == "table"
			then result.error.code
			else "INVALID_RESPONSE"
		return state
	end
	state.status = "ready"
	state.searchResults = if type(result.value.results) == "table" then result.value.results else {}
	state.errorCode = nil
	return state
end

function CoreRulesReaderViewModel.applyOpen(state: any, result: any): any
	if type(result) ~= "table" or result.ok ~= true or type(result.value) ~= "table" then
		state.status = "error"
		state.errorCode = if type(result) == "table" and type(result.error) == "table"
			then result.error.code
			else "INVALID_RESPONSE"
		return state
	end
	local value = result.value
	local chunk = value.chunk
	if type(chunk) ~= "table" or type(chunk.id) ~= "string" then
		state.status = "error"
		state.errorCode = "INVALID_RESPONSE"
		return state
	end
	state.status = "ready"
	state.openDocument = value.document
	state.openSection = value.section
	state.activeUri = chunk.uri
	state.chunks = { [chunk.id] = chunk }
	state.chunkOrder = { chunk.id }
	state.errorCode = nil
	return state
end

function CoreRulesReaderViewModel.appendChunk(state: any, result: any, direction: string): any
	if type(result) ~= "table" or result.ok ~= true or type(result.value) ~= "table" then
		state.status = "error"
		state.errorCode = if type(result) == "table" and type(result.error) == "table"
			then result.error.code
			else "INVALID_RESPONSE"
		return state
	end
	local chunk = result.value
	if type(chunk.id) ~= "string" or state.chunks[chunk.id] ~= nil then
		return state
	end
	state.chunks[chunk.id] = chunk
	if direction == "previous" then
		table.insert(state.chunkOrder, 1, chunk.id)
	else
		table.insert(state.chunkOrder, chunk.id)
	end
	state.activeUri = chunk.uri or state.activeUri
	state.status = "ready"
	state.errorCode = nil
	return state
end

function CoreRulesReaderViewModel.articleText(state: any): string
	local values = {}
	for _, chunkId in state.chunkOrder or {} do
		local chunk = state.chunks[chunkId]
		if type(chunk) == "table" and type(chunk.text) == "string" then
			table.insert(values, chunk.text)
		end
	end
	return table.concat(values, "\n\n")
end

function CoreRulesReaderViewModel.edgeChunkId(state: any, direction: string): string?
	local order = state.chunkOrder or {}
	if #order == 0 then
		return nil
	end
	local chunk = if direction == "previous" then state.chunks[order[1]] else state.chunks[order[#order]]
	if type(chunk) ~= "table" then
		return nil
	end
	return if direction == "previous" then chunk.previousChunkId else chunk.nextChunkId
end

return table.freeze(CoreRulesReaderViewModel)
