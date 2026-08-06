--!strict

return function(harness: any)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(1010, "dm")

	local deniedCreate = scenario:executeAs("player", 1010, "authoring.create_scene", {
		name = "Unauthorized Scene",
	})
	harness:expect(not deniedCreate.ok, "player cannot create an authoritative scene source")
	if not deniedCreate.ok then
		harness:equal(deniedCreate.error.code, "UNAUTHORIZED", "scene authoring denial is explicit")
	end

	local scene = scenario:execute("authoring.create_scene", {
		name = "Slice 10 Scene",
	})
	local sceneOutcome = scenario:expectOutcome(harness, scene, "Slice 10 creates a scene source")
	if sceneOutcome == nil then
		return
	end
	local sceneId = sceneOutcome.id
	harness:equal(sceneOutcome.revision, 1, "new scene source starts at revision one")
	harness:equal(sceneOutcome.name, "Slice 10 Scene", "scene source keeps its name")

	local publishWithoutCandidate = scenario:execute("authoring.publish", {
		sceneId = sceneId,
	})
	harness:expect(not publishWithoutCandidate.ok, "scene cannot publish without a valid candidate")
	if not publishWithoutCandidate.ok then
		harness:equal(
			publishWithoutCandidate.error.code,
			"CONFLICT",
			"missing candidate returns conflict"
		)
	end

	local object = scenario:execute("authoring.upsert_object", {
		sceneId = sceneId,
		object = {
			id = "object:slice-10-door",
			kind = "door",
			position = { x = 4, y = 0, z = 6 },
			state = { locked = false },
		},
	})
	local objectOutcome = scenario:expectOutcome(harness, object, "Slice 10 upserts a scene object")
	if objectOutcome == nil then
		return
	end
	harness:equal(
		objectOutcome.id,
		"object:slice-10-door",
		"provided stable object identity is retained"
	)
	harness:equal(
		scenario:snapshot().domains.scene_authoring.sources[sceneId].revision,
		2,
		"object mutation increments source revision"
	)

	local compile = scenario:execute("authoring.compile", {
		sceneId = sceneId,
	})
	local compileOutcome =
		scenario:expectOutcome(harness, compile, "Slice 10 compiles the scene source")
	if compileOutcome == nil then
		return
	end
	harness:expect(compileOutcome.valid == true, "valid source creates a valid candidate")
	harness:equal(compileOutcome.sourceRevision, 2, "candidate is bound to source revision")
	harness:equal(#compileOutcome.errors, 0, "valid candidate has no diagnostics")
	harness:expect(
		compileOutcome.objects["object:slice-10-door"] ~= nil,
		"candidate contains compiled object"
	)

	local sourceMutation = scenario:execute("authoring.upsert_object", {
		sceneId = sceneId,
		object = {
			id = "object:slice-10-floor",
			kind = "floor",
			position = { x = 0, y = 0, z = 0 },
		},
	})
	if
		scenario:expectOutcome(harness, sourceMutation, "Slice 10 mutates the source after compile")
		== nil
	then
		return
	end
	harness:expect(
		scenario:snapshot().domains.scene_authoring.candidates[sceneId] == nil,
		"source mutation invalidates the previous candidate"
	)

	local stalePublish = scenario:execute("authoring.publish", {
		sceneId = sceneId,
	})
	harness:expect(not stalePublish.ok, "stale or invalidated candidate cannot publish")
	if not stalePublish.ok then
		harness:equal(stalePublish.error.code, "CONFLICT", "stale candidate returns conflict")
	end

	local recompile = scenario:execute("authoring.compile", {
		sceneId = sceneId,
	})
	local recompileOutcome =
		scenario:expectOutcome(harness, recompile, "Slice 10 recompiles the current source")
	if recompileOutcome == nil then
		return
	end
	harness:equal(
		recompileOutcome.sourceRevision,
		3,
		"recompiled candidate uses current source revision"
	)
	local compiledObjectCount = 0
	if recompileOutcome.objects["object:slice-10-door"] ~= nil then
		compiledObjectCount += 1
	end
	if recompileOutcome.objects["object:slice-10-floor"] ~= nil then
		compiledObjectCount += 1
	end
	harness:equal(compiledObjectCount, 2, "recompiled candidate contains both stable objects")

	local publish = scenario:execute("authoring.publish", {
		sceneId = sceneId,
	})
	local publishOutcome = scenario:expectOutcome(
		harness,
		publish,
		"Slice 10 atomically publishes the current candidate"
	)
	if publishOutcome == nil then
		return
	end
	harness:expect(publishOutcome.valid == true, "published build remains valid")
	harness:equal(
		publishOutcome.sourceRevision,
		3,
		"published build points at current source revision"
	)
	harness:equal(
		scenario:snapshot().domains.scene_authoring.published[sceneId].sourceRevision,
		3,
		"published pointer stores the accepted candidate"
	)

	local invalidObject = scenario:execute("authoring.upsert_object", {
		sceneId = sceneId,
		object = {
			kind = "wall",
			position = { x = math.huge, y = 0, z = 0 },
		},
	})
	harness:expect(
		not invalidObject.ok,
		"invalid object position is rejected before source mutation"
	)
	if not invalidObject.ok then
		harness:equal(
			invalidObject.error.code,
			"VALIDATION_FAILED",
			"invalid authoring object uses validation error"
		)
	end
	harness:equal(
		scenario:snapshot().domains.scene_authoring.published[sceneId].sourceRevision,
		3,
		"failed source mutation preserves last published build"
	)

	local persisted = scenario:snapshot()
	local restored = ScenarioRuntime.new(1010, "dm")
	local restore = restored:restore(persisted)
	harness:expect(restore.ok, "Slice 10 authoring snapshot restores")
	if restore.ok then
		local restoredAuthoring = restored:snapshot().domains.scene_authoring
		harness:equal(
			restoredAuthoring.sources[sceneId].revision,
			3,
			"restore preserves source revision"
		)
		harness:equal(
			restoredAuthoring.published[sceneId].sourceRevision,
			3,
			"restore preserves published pointer"
		)
	end
end
