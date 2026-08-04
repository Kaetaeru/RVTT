--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local Version = require(ReplicatedStorage.RVTT.Shared.Core.Version)

local AuthorityRuntime = {}
AuthorityRuntime.__index = AuthorityRuntime

function AuthorityRuntime.new(registry, transactionCoordinator, outbox, diagnostics, snapshotJournal)
	local self = setmetatable({}, AuthorityRuntime)
	self.registry = registry
	self.transactionCoordinator = transactionCoordinator
	self.outbox = outbox
	self.diagnostics = diagnostics
	self.snapshotJournal = snapshotJournal
	self.processedCommands = {}
	self.state = {
		schemaVersion = Version.SCHEMA,
		authorityEpoch = Identity.new("epoch"),
		revision = 0,
		domains = {},
	}
	return self
end

function AuthorityRuntime:installDomain(domain)
	assert(self.state.domains[domain.id] == nil, "duplicate domain: " .. domain.id)
	self.state.domains[domain.id] = domain.initialState()
	domain.register(self.registry)
end

function AuthorityRuntime:execute(context, envelope)
	if self.processedCommands[envelope.commandId] ~= nil then
		return Result.err("DUPLICATE_COMMAND", "error.command.duplicate", false)
	end
	if envelope.authorityEpoch ~= nil and envelope.authorityEpoch ~= self.state.authorityEpoch then
		return Result.err("STALE_EPOCH", "error.authority.stale_epoch", false)
	end
	if envelope.expectedRevision ~= nil and envelope.expectedRevision ~= self.state.revision then
		return Result.err("STALE_REVISION", "error.authority.stale_revision", true, { revision = self.state.revision })
	end
	local descriptorResult = self.registry:get(envelope.commandType)
	if not descriptorResult.ok then
		return descriptorResult
	end
	local descriptor = descriptorResult.value
	local domainState = self.state.domains[descriptor.domainId]
	if domainState == nil then
		return Result.err("NOT_READY", "error.common.not_ready", true)
	end
	if descriptor.validate ~= nil and not descriptor.validate(envelope.payload) then
		return Result.err("VALIDATION_FAILED", "error.validation.failed", false)
	end
	if descriptor.authorize ~= nil and not descriptor.authorize(context, domainState, envelope.payload) then
		return Result.err("UNAUTHORIZED", "error.security.unauthorized", false)
	end
	local transactionResult = self.transactionCoordinator:execute(self.state, function(draft)
		local draftDomains = draft.domains :: { [string]: { [string]: unknown } }
		return descriptor.execute(context, draftDomains[descriptor.domainId], envelope.payload)
	end)
	if not transactionResult.ok then
		return transactionResult
	end
	self.state = transactionResult.value.state
	self.state.revision = (self.state.revision :: number) + 1
	self.processedCommands[envelope.commandId] = self.state.revision
	local event = self.outbox:append("authority.committed", {
		commandId = envelope.commandId,
		commandType = envelope.commandType,
		revision = self.state.revision,
	})
	self.snapshotJournal:record(self.state, event)
	return Result.ok({ revision = self.state.revision, outcome = transactionResult.value.outcome })
end

function AuthorityRuntime:snapshot()
	return self.state
end

return AuthorityRuntime
