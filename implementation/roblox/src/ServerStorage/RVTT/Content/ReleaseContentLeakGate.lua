--!strict

local ReleaseContentLeakGate = {}

local PUBLIC_PACKAGE_ID = "rvtt.core.rules"
local PRIVATE_PACKAGE_ID = "rvtt.test.rules.2024.integrated.ko"
local PUBLIC_PROFILES = {
	public = true,
	release = true,
	artifact = true,
}
local FORBIDDEN_TEXT_MARKERS = {
	PRIVATE_PACKAGE_ID,
	"kaetaeru/d-d-2024-",
	"rvtt_private_dnd2024_ko_source",
	"10-rulebooks/integrated-2024",
	"private-rule-chunk",
	"private_rule_chunk",
	"private-search-index",
	"private_search_index",
	"private-snippet-cache",
	"private_snippet_cache",
}
local FORBIDDEN_METADATA_KEYS = {
	credential = true,
	credentials = true,
	token = true,
	sourcerevision = true,
	sourcecommit = true,
	sourcebinding = true,
	sourcebindingkey = true,
	privatebinding = true,
}

local function addError(errors: { string }, code: string)
	if not table.find(errors, code) then
		table.insert(errors, code)
	end
end

local function inspectText(errors: { string }, value: string)
	local lower = string.lower(value)
	for _, marker in FORBIDDEN_TEXT_MARKERS do
		if string.find(lower, marker, 1, true) ~= nil then
			addError(errors, "PRIVATE_CONTENT_MARKER")
		end
	end
	for packageId in string.gmatch(lower, "rvtt%-rule://([%w%._%-]+)") do
		if packageId ~= PUBLIC_PACKAGE_ID then
			addError(errors, "NON_PUBLIC_RULE_LINK")
		end
	end
end

local function inspectMetadata(errors: { string }, metadata: any)
	if type(metadata) ~= "table" then
		return
	end
	for key, value in metadata do
		local normalized = string.lower(tostring(key)):gsub("[^%w]", "")
		if FORBIDDEN_METADATA_KEYS[normalized] then
			addError(errors, "PRIVATE_SOURCE_METADATA")
		end
		if type(value) == "string" then
			inspectText(errors, value)
		elseif type(value) == "table" then
			inspectMetadata(errors, value)
		end
	end
end

function ReleaseContentLeakGate.validate(artifact: any): any
	local errors = {}
	if type(artifact) ~= "table" then
		return { ok = false, errors = { "INVALID_ARTIFACT_INVENTORY" } }
	end
	if not PUBLIC_PROFILES[artifact.profile] then
		addError(errors, "INVALID_RELEASE_PROFILE")
	end
	if artifact.basePackageId ~= PUBLIC_PACKAGE_ID then
		addError(errors, "PUBLIC_BASE_PACKAGE_REQUIRED")
	end

	if type(artifact.packageIds) ~= "table" then
		addError(errors, "PACKAGE_INVENTORY_REQUIRED")
	else
		for _, packageId in artifact.packageIds do
			if packageId == PRIVATE_PACKAGE_ID then
				addError(errors, "PRIVATE_PACKAGE_PRESENT")
			end
			inspectText(errors, tostring(packageId))
		end
	end

	if type(artifact.files) ~= "table" then
		addError(errors, "OUTPUT_FILE_INVENTORY_REQUIRED")
	else
		for _, file in artifact.files do
			if type(file) ~= "table" or type(file.path) ~= "string" then
				addError(errors, "INVALID_OUTPUT_FILE")
			else
				inspectText(errors, file.path)
				if type(file.content) == "string" then
					inspectText(errors, file.content)
				end
				inspectMetadata(errors, file.metadata)
			end
		end
	end

	if type(artifact.ruleLinks) == "table" then
		for _, link in artifact.ruleLinks do
			inspectText(errors, tostring(link))
		end
	end

	local license = artifact.license
	if
		type(license) ~= "table"
		or license.packageId ~= PUBLIC_PACKAGE_ID
		or license.licenseId ~= "CC-BY-4.0"
		or license.attributionRequired ~= true
		or type(license.attributionText) ~= "string"
		or license.attributionText == ""
	then
		addError(errors, "SRD_ATTRIBUTION_REQUIRED")
	end

	return { ok = #errors == 0, errors = errors }
end

return ReleaseContentLeakGate
