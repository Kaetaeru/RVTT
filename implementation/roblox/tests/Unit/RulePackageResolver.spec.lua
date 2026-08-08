--!strict

local function copy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, nested in value do
		result[key] = copy(nested)
	end
	return result
end

local function packageById(packageIndex: { any }, packageId: string): any
	for _, package in packageIndex do
		if package.packageId == packageId then
			return package
		end
	end
	error("missing package fixture: " .. packageId)
end

local function readiness(package: any): any
	return {
		bindingPresent = true,
		sourceBindingKey = package.sourceBindingKey,
		revision = package.version,
		sourceRoot = package.sourceRoot,
		verifiedDigest = package.expectedSourceDigest,
		contentCounts = copy(package.expectedContentCounts),
	}
end

return function(h)
	local Resolver = require(game:GetService("ServerStorage").RVTT.Content.RulePackageResolver)
	local BuiltinPackIndex = require(game:GetService("ServerStorage").RVTT.Content.BuiltinPackIndex)
	local privatePackage = packageById(BuiltinPackIndex, "rvtt.test.rules.2024.integrated.ko")

	for _, profile in { "development", "test", "studio-acceptance" } do
		local result = Resolver.resolve(profile, { privateReadiness = readiness(privatePackage) })
		h:expect(result.ok, profile .. " resolves when private readiness is exact")
		h:equal(result.value.basePackageId, "rvtt.test.rules.2024.integrated.ko")
	end

	for _, profile in { "public", "release", "artifact" } do
		local result = Resolver.resolve(profile, {
			allowSrdFallback = "malformed",
			privateReadiness = { credential = "ignored" },
		})
		h:expect(result.ok, profile .. " always resolves to the public base")
		h:equal(result.value.basePackageId, "rvtt.core.rules")
		h:expect(
			not result.value.fallbackActive,
			profile .. " never exposes private fallback state"
		)
	end

	local unknown = Resolver.resolve("preview", {})
	local unknownCode = if unknown.error then unknown.error.code else nil
	local missing = Resolver.resolve("development", {})
	local missingCode = if missing.error then missing.error.code else nil
	local fallback = Resolver.resolve("development", { allowSrdFallback = true })
	local invalidFallback = Resolver.resolve("development", { allowSrdFallback = "true" })
	local invalidFallbackCode = if invalidFallback.error then invalidFallback.error.code else nil
	local unknownFallback = Resolver.resolve("preview", { allowSrdFallback = true })
	local unknownFallbackCode = if unknownFallback.error then unknownFallback.error.code else nil
	h:equal(unknownCode, "UNKNOWN_PROFILE")
	h:equal(missingCode, "PRIVATE_SOURCE_MISSING")
	h:expect(
		fallback.ok and fallback.value.fallbackActive,
		"explicit development fallback is visible"
	)
	h:equal(fallback.value.basePackageId, "rvtt.core.rules")
	h:equal(fallback.value.fallbackReasonCode, "INTEGRATED_TEST_PACK_UNAVAILABLE")
	h:equal(invalidFallbackCode, "PRIVATE_SOURCE_MISSING")
	h:equal(unknownFallbackCode, "UNKNOWN_PROFILE")
	local ambiguousIndex = copy(BuiltinPackIndex)
	table.insert(ambiguousIndex, copy(privatePackage))
	local ambiguous = Resolver.resolveWithIndex(ambiguousIndex, "test", {
		privateReadiness = readiness(privatePackage),
	})
	local ambiguousCode = if ambiguous.error then ambiguous.error.code else nil
	h:equal(ambiguousCode, "RULE_PROFILE_AMBIGUOUS")

	local failureFixtures = {
		{ field = "sourceBindingKey", value = "wrong", code = "SOURCE_BINDING_MISMATCH" },
		{ field = "revision", value = "wrong", code = "SOURCE_REVISION_MISMATCH" },
		{ field = "sourceRoot", value = "wrong", code = "SOURCE_ROOT_MISMATCH" },
		{ field = "verifiedDigest", value = "wrong", code = "SOURCE_DIGEST_MISMATCH" },
	}
	for _, fixture in failureFixtures do
		local evidence = readiness(privatePackage)
		evidence[fixture.field] = fixture.value
		local result = Resolver.resolve("test", { privateReadiness = evidence })
		local code = if result.error then result.error.code else nil
		h:equal(code, fixture.code)
	end
	for countName in readiness(privatePackage).contentCounts do
		local evidence = readiness(privatePackage)
		evidence.contentCounts[countName] += 1
		local result = Resolver.resolve("test", { privateReadiness = evidence })
		local code = if result.error then result.error.code else nil
		h:equal(code, "CONTENT_COUNT_MISMATCH")
	end
	local digestIndex = copy(BuiltinPackIndex)
	local digestPackage = packageById(digestIndex, "rvtt.test.rules.2024.integrated.ko")
	digestPackage.expectedSourceDigest = "fixture-expected-digest"
	local digestEvidence = readiness(digestPackage)
	digestEvidence.verifiedDigest = "fixture-different-digest"
	local digestResult = Resolver.resolveWithIndex(digestIndex, "test", {
		privateReadiness = digestEvidence,
	})
	local digestCode = if digestResult.error then digestResult.error.code else nil
	h:equal(digestCode, "SOURCE_DIGEST_MISMATCH")

	local revisionIndex = copy(BuiltinPackIndex)
	local revisionPackage = packageById(revisionIndex, "rvtt.test.rules.2024.integrated.ko")
	revisionPackage.version = "fixture-revision-from-index"
	local revisionResult = Resolver.resolveWithIndex(revisionIndex, "test", {
		privateReadiness = readiness(revisionPackage),
	})
	h:expect(revisionResult.ok, "private revision is derived from the injected package record")

	local countIndex = copy(BuiltinPackIndex)
	local countPackage = packageById(countIndex, "rvtt.test.rules.2024.integrated.ko")
	countPackage.expectedContentCounts.classes = 77
	local countResult = Resolver.resolveWithIndex(countIndex, "test", {
		privateReadiness = readiness(countPackage),
	})
	h:expect(countResult.ok, "private counts are derived from the injected package record")
	local staleCount = readiness(countPackage)
	staleCount.contentCounts.classes = 76
	local staleCountResult = Resolver.resolveWithIndex(countIndex, "test", {
		privateReadiness = staleCount,
	})
	local staleCountCode = if staleCountResult.error then staleCountResult.error.code else nil
	h:equal(staleCountCode, "CONTENT_COUNT_MISMATCH")

	local projected = Resolver.clientSafeStatus(
		Resolver.resolve("test", { privateReadiness = readiness(privatePackage) })
	)
	local allowed = {
		activeProfile = true,
		basePackageId = true,
		fallbackActive = true,
		fallbackReasonCode = true,
		attributionRequired = true,
	}
	for key in projected do
		h:expect(allowed[key] == true, "client status is allowlist-only: " .. key)
	end
	h:expect(projected.sourceBindingKey == nil, "client status excludes source binding")
	h:expect(projected.revision == nil, "client status excludes revision")
	h:expect(projected.contentCounts == nil, "client status excludes private counts")
end
