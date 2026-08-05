--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local ValueGuard = require(ReplicatedStorage.RVTT.Shared.Core.ValueGuard)
local Version = require(ReplicatedStorage.RVTT.Shared.Core.Version)

local MAX_IDEMPOTENCY_RECORDS = 4096

local AuthorityRuntime = {}
AuthorityRuntime.__index = AuthorityRuntime

function AuthorityRuntime.new(
	registry,
	transactionCoordinator,
	outbox,
	diagnostics,
	snapshotJournal
)
	local self = setmetatable({}, AuthorityRuntime)
	self.registry = registry
	self.transactionCoordinator = transactionCoordinator
	self.outbox = outbox
	self.diagnostics = diagnostics
	self.snapshotJournal = snapshotJournal
	self.processedCommands = {}
	self.processedOrder = {}
	self.commitListeners = {}
	self.domainInitializers = {}
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
	assert(type(domain.initialState) == "function", "domain initialState required: " .. domain.id)
	self.domainInitializers[domain.id] = domain.initialState
	self.state.domains[domain.id] = domain.initialState()
	domain.register(self.registry)
end

function AuthorityRuntime:onCommitted(callback)
	table.insert(self.commitListeners, callback)
end

function AuthorityRuntime:_remember(commandId: string, terminalResult)
	self.processedCommands[commandId] = terminalResult
	table.insert(self.processedOrder, commandId)
	if #self.processedOrder > MAX_IDEMPOTENCY_RECORDS then
		local expired = table.remove(self.processedOrder, 1)
		self.processedCommands[expired] = nil
	end
end

function AuthorityRuntime:execute(context, envelope)
	local previous = self.processedCommands[envelope.commandId]
	if previous ~= nil then
		return previous
	end
	if envelope.authorityEpoch ~= nil and envelope.authorityEpoch ~= self.state.authorityEpoch then
		return Result.err("STALE_EPOCH", "error.authority.stale_epoch", false)
	end
	if envelope.expectedRevision ~= nil and envelope.expectedRevision ~= self.state.revision then
		return Result.err(
			"STALE_REVISION",
			"error.authority.stale_revision",
			true,
			{ revision = self.state.revision }
		)
	end

	local descriptorResult = self.registry:get(envelope.commandType)
	if not descriptorResult.ok then
		return descriptorResult
	end
	local descriptor = descriptorResult.value
	if context.origin == "remote" and descriptor.remoteAllowed == false then
		return Result.err("UNAUTHORIZED", "error.security.unauthorized", false)
	end

	local domains = self.state.domains
	if not descriptor.authorize(context, domains, envelope.payload) then
		return Result.err("UNAUTHORIZED", "error.security.unauthorized", false)
	end
	if descriptor.validate ~= nil and not descriptor.validate(envelope.payload) then
		return Result.err("VALIDATION_FAILED", "error.validation.failed", false)
	end
	if domains[descriptor.domainId] == nil then
		return Result.err("NOT_READY", "error.common.not_ready", true)
	end

	local transactionResult = self.transactionCoordinator:execute(self.state, function(draft)
		local draftDomains = draft.domains :: { [string]: { [string]: any } }
		return descriptor.execute(
			context,
			draftDomains[descriptor.domainId],
			envelope.payload,
			draftDomains
		)
	end)
	if not transactionResult.ok then
		return transactionResult
	end

	local committedState = transactionResult.value.state
	committedState.revision = (self.state.revision :: number) + 1
	if descriptor.refreshAuthorityEpoch == true then
		committedState.authorityEpoch = Identity.new("epoch")
	end
	self.state = committedState

	local event = self.outbox:append("authority.committed", {
		commandId = envelope.commandId,
		commandType = envelope.commandType,
		revision = self.state.revision,
		authorityEpoch = self.state.authorityEpoch,
	})
	self.snapshotJournal:record(self.state, event)

	local terminalResult = Result.ok({
		commandId = envelope.commandId,
		revision = self.state.revision,
		authorityEpoch = self.state.authorityEpoch,
		outcome = transactionResult.value.outcome,
	})
	self:_remember(envelope.commandId, terminalResult)

	for _, callback in self.commitListeners do
		local ok, failure = xpcall(function()
			callback(self.state, event)
		end, debug.traceback)
		if not ok then
			self.diagnostics:record("error", "COMMIT_LISTENER_FAILED", { trace = failure })
		end
	end
	return terminalResult
end

function AuthorityRuntime:executeSystem(commandType: string, payload: { [string]: unknown })
	local commandId = Identity.new("system_command")
	return self:execute({
		player = nil,
		playerId = 0,
		role = "system",
		origin = "system",
		commandId = commandId,
		correlationId = commandId,
	}, {
		protocolVersion = Version.PROTOCOL,
		commandId = commandId,
		commandType = commandType,
		correlationId = commandId,
		authorityEpoch = self.state.authorityEpoch,
		expectedRevision = self.state.revision,
		payload = payload,
	})
end

function AuthorityRuntime:restore(document)
	if
		type(document) ~= "table"
		or document.schemaVersion ~= Version.SCHEMA
		or type(document.domains) ~= "table"
	then
		return Result.err("MIGRATION_FAILED", "error.persistence.migration_failed", false)
	end
	if not ValueGuard.isFiniteNumber(document.revision) then
		return Result.err("MIGRATION_FAILED", "error.persistence.migration_failed", false)
	end

	local revision = document.revision :: number
	if revision < 0 or revision % 1 ~= 0 then
		return Result.err("MIGRATION_FAILED", "error.persistence.migration_failed", false)
	end

	local restored = DeepCopy(document)
	local restoredDomains = {}
	for domainId, initialState in self.domainInitializers do
		local candidate = restored.domains[domainId]
		if type(candidate) == "table" then
			restoredDomains[domainId] = candidate
		else
			restoredDomains[domainId] = initialState()
		end
	end

	restored.schemaVersion = Version.SCHEMA
	restored.authorityEpoch = Identity.new("epoch")
	restored.revision = revision
	restored.domains = restoredDomains
	self.state = restored
	table.clear(self.processedCommands)
	table.clear(self.processedOrder)
	return Result.ok(true)
end

function AuthorityRuntime:snapshot()
	return self.state
end

return AuthorityRuntime
