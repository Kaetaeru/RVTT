--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService.RVTT.Server

local CommandRegistry = require(Server.Runtime.CommandRegistry)
local Diagnostics = require(Server.Runtime.Diagnostics)
local EventOutbox = require(Server.Runtime.EventOutbox)
local TransactionCoordinator = require(Server.Runtime.TransactionCoordinator)
local AuthorityRuntime = require(Server.Runtime.AuthorityRuntime)
local SnapshotJournal = require(Server.Persistence.SnapshotJournal)
local ServiceGraph = require(Server.Bootstrap.ServiceGraph)

local ScenarioRuntime = {}
ScenarioRuntime.__index = ScenarioRuntime

local function newAuthorityRuntime(): any
	local diagnostics = Diagnostics.new()
	local runtime = AuthorityRuntime.new(
		CommandRegistry.new(),
		TransactionCoordinator.new(diagnostics),
		EventOutbox.new(),
		diagnostics,
		SnapshotJournal.new(128)
	)
	for _, domain in ServiceGraph.domainModules() do
		runtime:installDomain(domain)
	end
	return runtime
end

function ScenarioRuntime.new(playerId: number, role: string?): any
	local self: any = setmetatable({}, ScenarioRuntime)
	self.runtime = newAuthorityRuntime()
	self.context = {
		player = { DisplayName = string.format("Scenario Player %d", playerId) },
		playerId = playerId,
		role = role or "dm",
		origin = "remote",
	}
	self.sequence = 0
	return self
end

function ScenarioRuntime._executeWithContext(
	self: any,
	context: any,
	commandType: string,
	payload: any,
	commandIdOverride: string?
): any
	self.sequence += 1
	local commandId = commandIdOverride
		or string.format("scenario:%d:%03d:%s", context.playerId, self.sequence, commandType)
	context.commandId = commandId
	context.correlationId = commandId
	local snapshot = self.runtime:snapshot()
	return self.runtime:execute(context, {
		commandId = commandId,
		commandType = commandType,
		correlationId = commandId,
		authorityEpoch = snapshot.authorityEpoch,
		expectedRevision = snapshot.revision,
		payload = payload,
	})
end

function ScenarioRuntime.execute(self: any, commandType: string, payload: any): any
	return self:_executeWithContext(self.context, commandType, payload, nil)
end

function ScenarioRuntime.executeAs(
	self: any,
	role: string,
	playerId: number,
	commandType: string,
	payload: any
): any
	local context = table.clone(self.context)
	context.playerId = playerId
	context.role = role
	context.player = { DisplayName = string.format("Scenario %s %d", role, playerId) }
	return self:_executeWithContext(context, commandType, payload, nil)
end

function ScenarioRuntime.executeDuplicate(
	self: any,
	commandId: string,
	commandType: string,
	payload: any
): any
	local context = table.clone(self.context)
	return self:_executeWithContext(context, commandType, payload, commandId)
end

function ScenarioRuntime.snapshot(self: any): any
	return self.runtime:snapshot()
end

function ScenarioRuntime.restore(self: any, document: any): any
	local restored = newAuthorityRuntime()
	local result = restored:restore(document)
	if result.ok then
		self.runtime = restored
	end
	return result
end

function ScenarioRuntime.expectOutcome(_self: any, harness: any, result: any, label: string): any
	harness:expect(result.ok, label)
	if not result.ok then
		return nil
	end
	return result.value.outcome
end

function ScenarioRuntime.bootstrapCharacter(
	self: any,
	harness: any,
	name: string,
	sceneId: string,
	abilities: any?
): string?
	local join = self:execute("session.join", {})
	if self:expectOutcome(harness, join, "scenario joins the campaign") == nil then
		return nil
	end

	local draft = self:execute("character.create_draft", { name = name })
	local draftOutcome = self:expectOutcome(harness, draft, "scenario creates a character draft")
	if draftOutcome == nil then
		return nil
	end
	local characterId = draftOutcome.id

	if abilities ~= nil then
		local update = self:execute("character.update_draft", {
			characterId = characterId,
			patch = { abilities = abilities },
		})
		if self:expectOutcome(harness, update, "scenario applies character abilities") == nil then
			return nil
		end
	end

	local activate = self:execute("character.activate", { characterId = characterId })
	if self:expectOutcome(harness, activate, "scenario activates the character") == nil then
		return nil
	end

	local selectCharacter = self:execute("session.select_character", {
		characterId = characterId,
	})
	if self:expectOutcome(harness, selectCharacter, "scenario selects the character") == nil then
		return nil
	end

	local ready = self:execute("session.ready", { ready = true })
	if self:expectOutcome(harness, ready, "scenario marks the player ready") == nil then
		return nil
	end

	local start = self:execute("session.start", { sceneId = sceneId })
	if self:expectOutcome(harness, start, "scenario starts the scene") == nil then
		return nil
	end

	local enter = self:execute("scene.enter", {
		sceneId = sceneId,
		actorId = characterId,
	})
	if self:expectOutcome(harness, enter, "scenario enters the scene") == nil then
		return nil
	end

	return characterId
end

return ScenarioRuntime
