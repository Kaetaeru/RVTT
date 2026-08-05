--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "journal", slice = 9 }

function Domain.initialState()
	return { documents = {}, pings = {} }
end

local function mayRead(context, document): boolean
	return context.role == "dm"
		or document.ownerUserId == context.playerId
		or document.visibility == "party"
		or document.visibility == "public"
end

function Domain.register(registry)
	registry:register({
		commandType = "journal.create",
		domainId = Domain.id,
		authorize = function(context)
			return Helpers.authenticated(context)
		end,
		validate = function(payload)
			return (
				payload.title == nil or (type(payload.title) == "string" and #payload.title <= 160)
			)
				and (
					payload.body == nil
					or (type(payload.body) == "string" and #payload.body <= 20000)
				)
		end,
		execute = function(context, state, payload)
			local documentId = Identity.new("journal")
			state.documents[documentId] = {
				id = documentId,
				ownerUserId = context.playerId,
				title = payload.title or "",
				body = payload.body or "",
				links = {},
				revision = 1,
				visibility = payload.visibility or "private",
			}
			return state.documents[documentId]
		end,
	})

	registry:register({
		commandType = "journal.edit",
		domainId = Domain.id,
		authorize = function(context, domains, payload)
			local document = domains.journal.documents[payload.documentId]
			return document ~= nil
				and (document.ownerUserId == context.playerId or context.role == "dm")
		end,
		validate = function(payload)
			return Helpers.hasString(payload, "documentId")
				and (payload.title == nil or (type(payload.title) == "string" and #payload.title <= 160))
				and (
					payload.body == nil
					or (type(payload.body) == "string" and #payload.body <= 20000)
				)
		end,
		execute = function(_, state, payload)
			local document = state.documents[payload.documentId]
			if document == nil then
				return Helpers.notFound("journal_document", payload.documentId)
			end
			if payload.title ~= nil then
				document.title = payload.title
			end
			if payload.body ~= nil then
				document.body = payload.body
			end
			if type(payload.links) == "table" then
				document.links = payload.links
			end
			document.revision += 1
			return document
		end,
	})

	registry:register({
		commandType = "journal.ping",
		domainId = Domain.id,
		authorize = function(context)
			return Helpers.authenticated(context)
		end,
		validate = function(payload)
			return Helpers.isVector(payload.position)
				and (
					payload.label == nil
					or (type(payload.label) == "string" and #payload.label <= 80)
				)
		end,
		execute = function(context, state, payload)
			local pingId = Identity.new("ping")
			state.pings[pingId] = {
				id = pingId,
				userId = context.playerId,
				position = payload.position,
				label = payload.label,
				expiresAt = os.time() + 30,
			}
			return state.pings[pingId]
		end,
	})
end

return table.freeze(Domain)
