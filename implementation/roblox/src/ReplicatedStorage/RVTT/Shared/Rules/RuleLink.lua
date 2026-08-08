--!strict

local RuleLink = {}

local SCHEME = "rvtt-rule://"
local SAFE_ID = "^[A-Za-z0-9][A-Za-z0-9%._%-]*$"

local function validId(value: any): boolean
	return type(value) == "string" and #value > 0 and string.match(value, SAFE_ID) ~= nil
end

function RuleLink.build(
	packageId: string,
	moduleId: string,
	documentId: string,
	anchorId: string?
): string?
	if not validId(packageId) or not validId(moduleId) or not validId(documentId) then
		return nil
	end
	if anchorId ~= nil and not validId(anchorId) then
		return nil
	end
	local uri = SCHEME .. packageId .. "/" .. moduleId .. "/" .. documentId
	if anchorId ~= nil then
		uri ..= "#" .. anchorId
	end
	return uri
end

function RuleLink.parse(uri: any): any?
	if type(uri) ~= "string" or string.sub(uri, 1, #SCHEME) ~= SCHEME then
		return nil
	end
	local remainder = string.sub(uri, #SCHEME + 1)
	local path, anchor = string.match(remainder, "^([^#]+)#?([^#]*)$")
	if path == nil then
		return nil
	end
	local packageId, moduleId, documentId = string.match(path, "^([^/]+)/([^/]+)/([^/]+)$")
	if not validId(packageId) or not validId(moduleId) or not validId(documentId) then
		return nil
	end
	local anchorId = if anchor ~= nil and anchor ~= "" then anchor else nil
	if anchorId ~= nil and not validId(anchorId) then
		return nil
	end
	return {
		packageId = packageId,
		moduleId = moduleId,
		documentId = documentId,
		anchorId = anchorId,
	}
end

function RuleLink.isValid(uri: any): boolean
	return RuleLink.parse(uri) ~= nil
end

return table.freeze(RuleLink)
