--!strict

return function(harness: any)
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local Builder = require(Server.Projection.ProjectionBuilder)
	local Preview = require(Server.Projection.ViewerProjectionPreview)
	local scenario = ScenarioRuntime.new(1, "dm")

	harness:expect(scenario:execute("session.join", {}).ok, "DM joins for preview scenario")
	harness:expect(
		scenario:executeAs("observer", 22, "session.join", {}).ok,
		"observer target joins"
	)
	local state = scenario:snapshot()
	state.domains.scene.actors["actor:hidden"] = {
		id = "actor:hidden",
		hidden = true,
		ownerUserId = 99,
		controllerUserId = 99,
		position = { x = 0, y = 0, z = 0 },
		incarnation = 1,
		disposition = "hostile",
	}
	state.domains.dm_workspace.recoveryRequests["recovery:secret"] = {
		id = "recovery:secret",
		target = "secret",
		createdAt = 1,
	}

	local builder = Builder.new()
	harness:equal(builder.sequenceByUserId[22], nil, "target has no live sequence before preview")
	local observerPreview = Preview.build(state, 22)
	harness:expect(observerPreview.ok, "server builds observer preview from session membership")
	harness:equal(
		builder.sequenceByUserId[22],
		nil,
		"preview does not consume live target sequence"
	)
	if observerPreview.ok then
		local domains = observerPreview.value.payload.domains
		harness:expect(
			next(domains.dm_workspace) == nil,
			"preview applies negative disclosure to DM workspace"
		)
		harness:equal(
			domains.scene.actors["actor:hidden"],
			nil,
			"preview hides an actor unknown to target"
		)
		harness:equal(
			observerPreview.value.target.role,
			"observer",
			"target role is derived from authoritative session"
		)
		harness:equal(
			observerPreview.value.revision,
			state.revision,
			"preview carries authority revision"
		)
	end

	local live = builder:build(state, 22, "observer")
	harness:equal(live.projectionSequence, 1, "first live projection still starts at sequence one")
	Preview.build(state, 22)
	harness:equal(
		builder.sequenceByUserId[22],
		1,
		"subsequent preview leaves live sequence unchanged"
	)

	local missing = Preview.build(state, 404)
	harness:expect(
		not missing.ok and missing.error.code == "PREVIEW_TARGET_NOT_FOUND",
		"unknown target fails closed"
	)
	local dmTarget = Preview.build(state, 1)
	harness:expect(
		not dmTarget.ok and dmTarget.error.code == "PREVIEW_TARGET_INVALID_ROLE",
		"DM target is not accepted as a player-view preview"
	)
end
