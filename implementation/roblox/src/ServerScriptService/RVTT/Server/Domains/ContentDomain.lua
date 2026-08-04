--!strict

local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "content", slice = 12 }

function Domain.initialState()
    return { packs = {}, active = {}, localization = {} }
end

local function dm(context): boolean
    return Helpers.requireRole(context, { "dm" })
end

local function validManifest(manifest): boolean
    return type(manifest) == "table"
        and Helpers.hasString(manifest, "packId", 128)
        and Helpers.hasString(manifest, "version", 64)
        and (manifest.rightsStatus == "approved" or manifest.rightsStatus == "original" or manifest.rightsStatus == "blocked")
        and (manifest.dependencies == nil or type(manifest.dependencies) == "table")
end

function Domain.register(registry)
    registry:register({
        commandType = "content.register_pack",
        domainId = Domain.id,
        authorize = dm,
        validate = function(payload)
            return validManifest(payload.manifest)
        end,
        execute = function(_, state, payload)
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
        validate = function(payload)
            return Helpers.hasString(payload, "packId")
        end,
        execute = function(_, state, payload)
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
        validate = function(payload)
            return Helpers.hasString(payload, "locale", 32) and type(payload.entries) == "table"
        end,
        execute = function(_, state, payload)
            state.localization[payload.locale] = payload.entries
            local count = 0
            for _ in payload.entries do count += 1 end
            return { locale = payload.locale, count = count }
        end,
    })
end

return table.freeze(Domain)
