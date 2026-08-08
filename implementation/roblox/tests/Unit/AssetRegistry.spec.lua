--!strict

local function contains(errors: { string }, fragment: string): boolean
	for _, message in errors do
		if string.find(message, fragment, 1, true) ~= nil then
			return true
		end
	end
	return false
end

local function identity()
	return {
		packageId = "rvtt.test.assets",
		version = "1.0.0",
		assetSetDigest = "fixture-digest",
	}
end

local function manifest()
	return {
		packageId = "rvtt.test.assets",
		version = "1.0.0",
		assetSetDigest = "fixture-digest",
		clientExportAllowed = true,
	}
end

local function profile()
	return {
		forbiddenPayloadClasses = {
			Script = true,
			LocalScript = true,
			ModuleScript = true,
			RemoteEvent = true,
			RemoteFunction = true,
		},
	}
end

local function token(assetId: string): any
	return {
		assetId = assetId,
		stableKey = assetId,
		packageId = "rvtt.test.assets",
		version = "1.0.0",
		kind = "token-prefab",
		displayNameKey = "test.asset.token",
		sourceContentHash = "test-only-source-hash",
		runtimeContentAddress = "test-only/runtime/token",
		publishedAssetId = "rbxassetid://1",
		thumbnailAssetId = "rbxassetid://2",
		bounds = { x = 4, y = 6, z = 4 },
		pivot = { mode = "feet", x = 0, y = -3, z = 0 },
		placementProfile = {
			footprint = { x = 4, y = 0, z = 4 },
			selectionBounds = { x = 4, y = 6, z = 4 },
			surface = "floor",
		},
		collisionProfile = { mode = "query-only" },
		navigationProfile = { mode = "token" },
		interactionCapabilities = { "select", "inspect" },
		performanceBudget = { instances = 3, triangles = 100, textureMemoryKb = 64 },
		dependencies = {},
		rights = {
			licenseId = "TEST-ONLY",
			status = "synthetic_fixture",
			redistributable = false,
			attributionRequired = false,
		},
		provenance = {
			sourceType = "synthetic_test_fixture",
			sourceReference = "AssetRegistry.spec.lua",
			sourceRevision = "1",
			privateNote = "must never reach the client",
		},
		rigProfile = { mode = "none" },
		animationProfile = { mode = "none" },
		cameraFocus = { height = 3 },
		sourcePayloadClasses = { "Model", "MeshPart" },
		clientExportAllowed = true,
		serverValidationSecret = "must never reach the client",
	}
end

local function prop(assetId: string): any
	local value = token(assetId)
	value.kind = "prop-prefab"
	value.rigProfile = nil
	value.animationProfile = nil
	value.cameraFocus = nil
	value.interactionSockets = {}
	value.stateVariants = {}
	return value
end

return function(h)
	local Content = game:GetService("ServerStorage").RVTT.Content
	local Validator = require(Content.AssetRegistryValidator)
	local ClientAssetViewBuilder = require(Content.ClientAssetViewBuilder)

	local empty = Validator.validatePackage(identity(), manifest(), {}, profile())
	h:expect(empty.ok, "empty production registry is valid")

	local syntheticToken = token("asset.test.token.guard")
	local syntheticProp = prop("asset.test.prop.crate")
	syntheticProp.dependencies = { syntheticToken.assetId }
	local valid = Validator.validatePackage(
		identity(),
		manifest(),
		{ syntheticToken, syntheticProp },
		profile()
	)
	h:expect(valid.ok, "synthetic test-only token and prop are valid")

	local duplicate = token("asset.test.duplicate")
	local duplicateResult =
		Validator.validatePackage(identity(), manifest(), { duplicate, duplicate }, profile())
	h:expect(
		not duplicateResult.ok and contains(duplicateResult.errors, "duplicate assetId"),
		"duplicate asset id is rejected"
	)
	local duplicateKeyA = token("asset.test.key-a")
	local duplicateKeyB = token("asset.test.key-b")
	duplicateKeyB.stableKey = duplicateKeyA.stableKey
	local duplicateKeyResult = Validator.validatePackage(
		identity(),
		manifest(),
		{ duplicateKeyA, duplicateKeyB },
		profile()
	)
	h:expect(
		contains(duplicateKeyResult.errors, "duplicate stableKey"),
		"duplicate package-local stable key is rejected"
	)

	local missingRights = token("asset.test.missing-rights")
	missingRights.rights = {}
	missingRights.provenance = {}
	local rightsResult =
		Validator.validatePackage(identity(), manifest(), { missingRights }, profile())
	h:expect(
		contains(rightsResult.errors, "missing rights metadata"),
		"missing rights are rejected"
	)
	h:expect(
		contains(rightsResult.errors, "missing provenance metadata"),
		"missing provenance is rejected"
	)

	local missingGeometry = token("asset.test.missing-geometry")
	missingGeometry.pivot = nil
	missingGeometry.placementProfile = nil
	local geometryResult =
		Validator.validatePackage(identity(), manifest(), { missingGeometry }, profile())
	h:expect(contains(geometryResult.errors, "token pivot"), "missing token feet pivot is rejected")
	h:expect(
		contains(geometryResult.errors, "footprint and selectionBounds"),
		"missing token footprint is rejected"
	)

	local cycleA = token("asset.test.cycle-a")
	local cycleB = token("asset.test.cycle-b")
	cycleA.dependencies = { cycleB.assetId }
	cycleB.dependencies = { cycleA.assetId }
	local cycleResult =
		Validator.validatePackage(identity(), manifest(), { cycleA, cycleB }, profile())
	h:expect(contains(cycleResult.errors, "dependency cycle"), "dependency cycle is rejected")
	local missingDependency = token("asset.test.missing-dependency")
	missingDependency.dependencies = { "asset.test.does-not-exist" }
	local dependencyResult =
		Validator.validatePackage(identity(), manifest(), { missingDependency }, profile())
	h:expect(
		contains(dependencyResult.errors, "invalid dependency"),
		"unknown dependency is rejected"
	)

	local private = token("asset.test.private")
	private.clientExportAllowed = false
	local view = ClientAssetViewBuilder.project(manifest(), { syntheticToken, private })
	h:equal(#view, 1, "private asset is absent without placeholder or count")
	h:expect(
		(view :: any).count == nil and (view :: any).placeholder == nil,
		"client view exposes no hidden count or placeholder"
	)
	h:equal(view[1].assetId, syntheticToken.assetId, "public test asset remains in client view")
	h:expect(view[1].provenance == nil, "provenance is absent from client view")
	h:expect(view[1].sourceContentHash == nil, "source hash is absent from client view")
	h:expect(
		view[1].runtimeContentAddress == nil,
		"unpublished runtime address is absent from client view"
	)
	h:expect(view[1].serverValidationSecret == nil, "server-only field is absent from client view")

	local allowed = {
		assetId = true,
		packageId = true,
		version = true,
		kind = true,
		displayNameKey = true,
		publishedAssetId = true,
		thumbnailAssetId = true,
		bounds = true,
		pivot = true,
		placementProfile = true,
		collisionProfile = true,
		navigationProfile = true,
		interactionCapabilities = true,
		performanceBudget = true,
		rights = true,
	}
	for field in view[1] do
		h:expect(allowed[field] == true, "client view contains only allowlisted fields: " .. field)
	end
	local privateManifest = manifest()
	privateManifest.clientExportAllowed = false
	h:equal(
		#ClientAssetViewBuilder.project(privateManifest, { syntheticToken }),
		0,
		"non-exportable package is completely absent"
	)

	local driftedIdentity = identity()
	driftedIdentity.version = "2.0.0"
	local driftResult = Validator.validatePackage(driftedIdentity, manifest(), {}, profile())
	h:expect(
		contains(driftResult.errors, "source/server identity drift"),
		"source/server identity drift is rejected"
	)

	local executable = token("asset.test.executable")
	executable.sourcePayloadClasses = { "Model", "ModuleScript", "RemoteEvent" }
	local executableResult =
		Validator.validatePackage(identity(), manifest(), { executable }, profile())
	h:expect(
		contains(executableResult.errors, "executable payload class"),
		"executable source payload is rejected"
	)

	local negativeBudget = token("asset.test.negative-budget")
	negativeBudget.performanceBudget.triangles = -1
	local budgetResult =
		Validator.validatePackage(identity(), manifest(), { negativeBudget }, profile())
	h:expect(
		contains(budgetResult.errors, "invalid performanceBudget"),
		"negative performance budget is rejected"
	)
end
