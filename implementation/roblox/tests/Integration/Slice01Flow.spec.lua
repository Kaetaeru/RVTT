--!strict

return function(harness)
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local CommandRegistry = require(Server.Runtime.CommandRegistry)
	local Diagnostics = require(Server.Runtime.Diagnostics)
	local EventOutbox = require(Server.Runtime.EventOutbox)
	local TransactionCoordinator = require(Server.Runtime.TransactionCoordinator)
	local AuthorityRuntime = require(Server.Runtime.AuthorityRuntime)
	local SnapshotJournal = require(Server.Persistence.SnapshotJournal)
	local ServiceGraph = require(Server.Bootstrap.ServiceGraph)

	local function newRuntime()
		local diagnostics = Diagnostics.new()
		local runtime = AuthorityRuntime.new(
			CommandRegistry.new(),
			TransactionCoordinator.new(diagnostics),
			EventOutbox.new(),
			diagnostics,
			SnapshotJournal.new(64)
		)
		for _, domain in ServiceGraph.domainModules() do
			runtime:installDomain(domain)
		end
		return runtime
	end

	local runtime = newRuntime()
	local context = {
		player = { DisplayName = "Slice 01 Player" },
		playerId = 101,
		role = "dm",
		origin = "remote",
	}
	local commandSequence = 0

	local function execute(commandType: string, payload: any): any
		commandSequence += 1
		local commandId = string.format("slice01:%02d:%s", commandSequence, commandType)
		context.commandId = commandId
		context.correlationId = commandId
		local snapshot = runtime:snapshot()
		return runtime:execute(context, {
			commandId = commandId,
			commandType = commandType,
			correlationId = commandId,
			authorityEpoch = snapshot.authorityEpoch,
			expectedRevision = snapshot.revision,
			payload = payload,
		})
	end

	local join = execute("session.join", {})
	harness:expect(join.ok, "Slice 01 joins the campaign")

	local draft = execute("character.create_draft", { name = "Slice 01 Hero" })
	harness:expect(draft.ok, "Slice 01 creates a character draft")
	local characterId = draft.value.outcome.id

	local activate = execute("character.activate", { characterId = characterId })
	harness:expect(activate.ok, "Slice 01 activates the character")

	local selectCharacter = execute("session.select_character", { characterId = characterId })
	harness:expect(selectCharacter.ok, "Slice 01 selects the active character")

	local ready = execute("session.ready", { ready = true })
	harness:expect(ready.ok, "Slice 01 marks the player ready")

	local sceneId = "scene:slice-01-acceptance"
	local start = execute("session.start", { sceneId = sceneId })
	harness:expect(start.ok, "Slice 01 starts the selected scene")

	local enter = execute("scene.enter", { sceneId = sceneId, actorId = characterId })
	harness:expect(enter.ok, "Slice 01 enters the active scene")

	local destination = { x = 12, y = 0, z = 8 }
	local move = execute("movement.commit", {
		actorId = characterId,
		destination = destination,
	})
	harness:expect(move.ok, "Slice 01 commits a server-authoritative move")

	local persisted = runtime:snapshot()
	local domains = persisted.domains
	local userKey = tostring(context.playerId)
	local actor = domains.scene.actors[characterId]

	harness:expect(domains.session.memberships[userKey] ~= nil, "membership persists")
	harness:equal(
		domains.session.selectedCharacter[userKey],
		characterId,
		"selected character persists"
	)
	harness:expect(domains.session.ready[userKey] == true, "ready state persists")
	harness:equal(domains.session.phase, "active", "active phase persists")
	harness:equal(domains.session.sceneId, sceneId, "session scene persists")
	harness:expect(actor ~= nil, "scene actor persists")
	harness:equal(actor.position.x, destination.x, "actor X position persists")
	harness:equal(actor.position.z, destination.z, "actor Z position persists")

	local restoredRuntime = newRuntime()
	local restore = restoredRuntime:restore(persisted)
	harness:expect(restore.ok, "Slice 01 authority snapshot restores")
	local reconnect = restoredRuntime:executeSystem("session.connection", {
		userId = context.playerId,
		status = "connected",
	})
	harness:expect(reconnect.ok, "Slice 01 reconnect transition commits")

	local restored = restoredRuntime:snapshot().domains
	local restoredActor = restored.scene.actors[characterId]
	harness:equal(
		restored.session.selectedCharacter[userKey],
		characterId,
		"reconnect restores selected character"
	)
	harness:equal(restored.session.sceneId, sceneId, "reconnect restores the scene")
	harness:expect(restoredActor ~= nil, "reconnect restores the actor")
	harness:equal(restoredActor.position.x, destination.x, "reconnect restores actor X")
	harness:equal(restoredActor.position.z, destination.z, "reconnect restores actor Z")
	harness:equal(
		restored.session.connections[userKey],
		"connected",
		"reconnect restores connection"
	)
end
