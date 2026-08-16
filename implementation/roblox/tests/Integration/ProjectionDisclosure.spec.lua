--!strict

return function(harness)
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local Builder = require(Server.Projection.ProjectionBuilder).new()
	local state = {
		schemaVersion = 1,
		authorityEpoch = "epoch:test",
		revision = 1,
		domains = {
			character = {
				drafts = {},
				characters = {
					owned = {
						id = "owned",
						ownerUserId = 1,
						name = "Owned",
						level = 1,
						abilities = { strength = 18 },
						status = "active",
					},
					other = {
						id = "other",
						ownerUserId = 2,
						name = "Other",
						level = 2,
						abilities = { strength = 20 },
						status = "active",
					},
				},
			},
			scene = {
				actors = {
					owned_actor = {
						id = "owned_actor",
						ownerUserId = 1,
						position = { x = 0, y = 0, z = 0 },
					},
					hidden_actor = {
						id = "hidden_actor",
						ownerUserId = 2,
						hidden = true,
						position = { x = 4, y = 0, z = 0 },
					},
				},
				objects = {},
			},
			encounter = {
				active = {
					id = "encounter:disclosure",
					status = "active",
					round = 1,
					cursor = 1,
					timeline = {
						{ actorId = "hidden_actor", initiative = 20 },
						{ actorId = "owned_actor", initiative = 10 },
					},
					opportunities = { action = true, reaction = true },
					movementRemaining = 24,
				},
				checkpoints = { { snapshot = "dm-only" } },
				history = {},
			},
			rules = {
				rollRecords = {
					hidden_roll = {
						data = { attackerId = "hidden_actor", targetId = "owned_actor" },
					},
				},
				actorStates = {
					owned_actor = { currentHitPoints = 10, maximumHitPoints = 10 },
					hidden_actor = { currentHitPoints = 99, maximumHitPoints = 99 },
				},
				challenges = {},
				conditions = {},
			},
			dm_workspace = { recoveryRequests = { secret = { target = "hidden" } } },
		},
	}
	local projection = Builder:build(state, 1, "player")
	harness:expect(
		projection.payload.domains.dm_workspace.secret == nil,
		"DM workspace is not disclosed"
	)
	harness:expect(
		projection.payload.domains.character.characters.owned.abilities ~= nil,
		"owner receives full character"
	)
	harness:expect(
		projection.payload.domains.character.characters.other.abilities == nil,
		"other character is summarized"
	)
	harness:equal(
		#projection.payload.domains.encounter.active.timeline,
		1,
		"hidden encounter participant is omitted from player timeline"
	)
	harness:expect(
		projection.payload.domains.encounter.active.activeActorId == nil,
		"hidden active actor is not disclosed"
	)
	harness:expect(
		projection.payload.domains.encounter.active.opportunities == nil,
		"another actor's opportunity ledger is not disclosed"
	)
	harness:expect(
		projection.payload.domains.rules.actorStates.hidden_actor == nil,
		"hidden actor resource state is omitted"
	)
	harness:expect(
		projection.payload.domains.rules.rollRecords.hidden_roll == nil,
		"roll records referencing a hidden actor are omitted"
	)

	state.domains.encounter.active.cursor = 2
	local controlledTurn = Builder:build(state, 1, "player")
	harness:expect(
		controlledTurn.payload.domains.encounter.active.activeActorId == "owned_actor",
		"visible controlled active actor is projected"
	)
	harness:expect(
		controlledTurn.payload.domains.encounter.active.opportunities.reaction == true,
		"controller receives its projected reaction opportunity"
	)
	local dmProjection = Builder:build(state, 9, "dm")
	harness:equal(
		#dmProjection.payload.domains.encounter.active.timeline,
		2,
		"DM retains the full encounter timeline"
	)
	harness:expect(
		dmProjection.payload.domains.rules.actorStates.hidden_actor ~= nil,
		"DM retains hidden actor state"
	)
end
