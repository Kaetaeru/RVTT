--!strict

return function(harness)
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local Registry = require(Server.Runtime.CommandRegistry).new()
	local Diagnostics = require(Server.Runtime.Diagnostics).new()
	local Outbox = require(Server.Runtime.EventOutbox).new()
	local Journal = require(Server.Persistence.SnapshotJournal).new(32)
	local Transactions = require(Server.Runtime.TransactionCoordinator).new(Diagnostics)
	local Runtime = require(Server.Runtime.AuthorityRuntime).new(
		Registry,
		Transactions,
		Outbox,
		Diagnostics,
		Journal
	)
	for _, domain in require(Server.Bootstrap.ServiceGraph).domainModules() do
		Runtime:installDomain(domain)
	end

	local Builder = require(Server.Projection.ProjectionBuilder).new()
	local players = {
		dm = { DisplayName = "DM" },
		player = { DisplayName = "Player" },
		observer = { DisplayName = "Observer" },
	}
	local contexts = {
		dm = {
			player = players.dm,
			playerId = 101,
			role = "dm",
			origin = "remote",
		},
		player = {
			player = players.player,
			playerId = 202,
			role = "player",
			origin = "remote",
		},
		observer = {
			player = players.observer,
			playerId = 303,
			role = "observer",
			origin = "remote",
		},
	}

	local function execute(
		context: any,
		commandId: string,
		commandType: string,
		payload: any,
		expectedRevision: number
	): any
		context.commandId = commandId
		context.correlationId = commandId
		return Runtime:execute(context, {
			commandId = commandId,
			commandType = commandType,
			correlationId = commandId,
			authorityEpoch = Runtime:snapshot().authorityEpoch,
			expectedRevision = expectedRevision,
			payload = payload,
		})
	end

	local dmJoin = execute(contexts.dm, "multi:join:dm", "session.join", {}, 0)
	harness:expect(dmJoin.ok, "DM joins at the initial revision")

	local stalePlayerJoin =
		execute(contexts.player, "multi:join:player:stale", "session.join", {}, 0)
	harness:expect(
		not stalePlayerJoin.ok and stalePlayerJoin.error.code == "STALE_REVISION",
		"concurrent player join detects a stale revision"
	)

	local playerJoin = execute(contexts.player, "multi:join:player", "session.join", {}, 1)
	local observerJoin = execute(contexts.observer, "multi:join:observer", "session.join", {}, 2)
	harness:expect(playerJoin.ok, "player retries join after resync")
	harness:expect(observerJoin.ok, "observer joins the shared session")
	harness:equal(Runtime:snapshot().revision, 3, "three memberships commit exactly once")

	local memberships = Runtime:snapshot().domains.session.memberships
	local dmMembership: any = rawget(memberships, "101")
	local playerMembership: any = rawget(memberships, "202")
	local observerMembership: any = rawget(memberships, "303")
	harness:equal(dmMembership.role, "dm", "DM membership retains its role")
	harness:equal(playerMembership.role, "player", "player membership retains its role")
	harness:equal(observerMembership.role, "observer", "observer membership retains its role")

	local observerDmCommand = execute(
		contexts.observer,
		"multi:observer:dm-command",
		"dm.quick_action",
		{ actionId = "forbidden" },
		3
	)
	harness:expect(
		not observerDmCommand.ok and observerDmCommand.error.code == "UNAUTHORIZED",
		"observer cannot execute a DM command"
	)
	harness:equal(Runtime:snapshot().revision, 3, "unauthorized command does not commit")

	local dmCommand = execute(
		contexts.dm,
		"multi:dm:quick-action",
		"dm.quick_action",
		{ actionId = "authorized" },
		3
	)
	harness:expect(dmCommand.ok, "DM command commits")

	local dmDraft =
		execute(contexts.dm, "multi:draft:dm", "character.create_draft", { name = "DM Draft" }, 4)
	local stalePlayerDraft = execute(
		contexts.player,
		"multi:draft:player:stale",
		"character.create_draft",
		{ name = "Player Draft" },
		4
	)
	harness:expect(dmDraft.ok, "DM draft commits")
	harness:expect(
		not stalePlayerDraft.ok and stalePlayerDraft.error.code == "STALE_REVISION",
		"concurrent draft creation detects a stale revision"
	)

	local playerDraft = execute(
		contexts.player,
		"multi:draft:player",
		"character.create_draft",
		{ name = "Player Draft" },
		5
	)
	harness:expect(playerDraft.ok, "player draft commits after resync")
	local dmDraftId = dmDraft.value.outcome.id
	local playerDraftId = playerDraft.value.outcome.id

	local state = Runtime:snapshot()
	local dmProjection = Builder:build(state, 101, "dm")
	local playerProjection = Builder:build(state, 202, "player")
	local observerProjection = Builder:build(state, 303, "observer")
	local dmCharacters = dmProjection.payload.domains.character.drafts
	local playerCharacters = playerProjection.payload.domains.character.drafts
	local observerCharacters = observerProjection.payload.domains.character.drafts

	harness:expect(
		dmCharacters[dmDraftId] ~= nil and dmCharacters[playerDraftId] ~= nil,
		"DM projection contains both private drafts"
	)
	harness:expect(
		playerCharacters[dmDraftId] == nil and playerCharacters[playerDraftId] ~= nil,
		"player projection contains only the owned draft"
	)
	harness:expect(
		observerCharacters[dmDraftId] == nil and observerCharacters[playerDraftId] == nil,
		"observer projection contains no private drafts"
	)
	harness:expect(
		next(dmProjection.payload.domains.dm_workspace) ~= nil,
		"DM receives the workspace projection"
	)
	harness:expect(
		next(playerProjection.payload.domains.dm_workspace) == nil
			and next(observerProjection.payload.domains.dm_workspace) == nil,
		"non-DM viewers do not receive the workspace projection"
	)

	local disconnected = Runtime:executeSystem("session.connection", {
		userId = 202,
		status = "disconnected",
	})
	local reconnected = Runtime:executeSystem("session.connection", {
		userId = 202,
		status = "connected",
	})
	harness:expect(disconnected.ok and reconnected.ok, "connection transitions commit")
	local connections = Runtime:snapshot().domains.session.connections
	local connection: any = rawget(connections, "202")
	harness:equal(connection, "connected", "reconnection restores connected status")

	local dmProjectionAgain = Builder:build(Runtime:snapshot(), 101, "dm")
	harness:expect(
		dmProjectionAgain.projectionSequence > dmProjection.projectionSequence,
		"each viewer projection sequence advances independently"
	)
	harness:equal(
		playerProjection.projectionSequence,
		1,
		"another viewer starts with its own projection sequence"
	)
end
