--!strict

local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "content", slice = 12 }

function Domain.initialState()
	return { packs = {}, active = {}, localization = {} }
end

local function dm(context: any): boolean
	return Helpers.requireRole(context, { "dm" })
end

local function validManifest(manifest: any): boolean
	local definitions = if type(manifest) == "table" then manifest.definitions else nil
	if definitions ~= nil then
		if type(definitions) ~= "table" then
			return false
		end
		for collectionName, collection in definitions do
			if
				(collectionName ~= "characterSheets" and collectionName ~= "items")
				or type(collection) ~= "table"
			then
				return false
			end
			for definitionId, definition in collection do
				if
					type(definitionId) ~= "string"
					or definitionId == ""
					or #definitionId > 128
					or type(definition) ~= "table"
				then
					return false
				end
			end
		end
	end
	return type(manifest) == "table"
		and Helpers.hasString(manifest, "packId", 128)
		and Helpers.hasString(manifest, "version", 64)
		and (manifest.rightsStatus == "approved" or manifest.rightsStatus == "original" or manifest.rightsStatus == "blocked")
		and (manifest.dependencies == nil or type(manifest.dependencies) == "table")
end

function Domain.register(registry: any)
	registry:register({
		commandType = "content.register_pack",
		domainId = Domain.id,
		authorize = dm,
		validate = function(payload: any)
			return validManifest(payload.manifest)
		end,
		execute = function(_: any, state: any, payload: any)
			local manifest = payload.manifest
			if state.packs[manifest.packId] ~= nil then
				return Helpers.conflict("pack already registered")
			end
			state.packs[manifest.packId] = manifest
			return manifest
		end,
	})

	registry:register({
		commandType = "content.activate_pack",
		domainId = Domain.id,
		authorize = dm,
		validate = function(payload: any)
			return Helpers.hasString(payload, "packId")
		end,
		execute = function(_: any, state: any, payload: any)
			local pack = state.packs[payload.packId]
			if pack == nil then
				return Helpers.notFound("content_pack", payload.packId)
			end
			if pack.rightsStatus ~= "approved" and pack.rightsStatus ~= "original" then
				return Helpers.conflict("pack rights are not approved")
			end
			for _, dependency in pack.dependencies or {} do
				if state.active[dependency] == nil then
					return Helpers.conflict("pack dependency is inactive: " .. dependency)
				end
			end
			state.active[payload.packId] = pack.version
			return { packId = payload.packId, version = pack.version }
		end,
	})

	registry:register({
		commandType = "content.localization",
		domainId = Domain.id,
		authorize = dm,
		validate = function(payload: any)
			return Helpers.hasString(payload, "locale", 32) and type(payload.entries) == "table"
		end,
		execute = function(_: any, state: any, payload: any)
			state.localization[payload.locale] = payload.entries
			local count = 0
			for _ in payload.entries do
				count += 1
			end
			return { locale = payload.locale, count = count }
		end,
	})
end

return table.freeze(Domain)
