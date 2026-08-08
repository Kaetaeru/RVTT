--!strict

local function readiness(): any
	return {
		bindingPresent = true,
		sourceBindingKey = "RVTT_PRIVATE_DND2024_KO_SOURCE",
		revision = "d3d574725e0ecdfd05cb69fa32cf66196e3a8ee4",
		sourceRoot = "10-RULEBOOKS/integrated-2024",
		contentCounts = {
			classes = 12,
			subclasses = 48,
			backgrounds = 16,
			species = 10,
			feats = 75,
			spells = 391,
		},
	}
end

return function(h)
	local Resolver = require(game:GetService("ServerStorage").RVTT.Content.RulePackageResolver)

	for _, profile in { "development", "test", "studio-acceptance" } do
		local result = Resolver.resolve(profile, { privateReadiness = readiness() })
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

	local failureFixtures = {
		{ field = "sourceBindingKey", value = "wrong", code = "SOURCE_BINDING_MISMATCH" },
		{ field = "revision", value = "wrong", code = "SOURCE_REVISION_MISMATCH" },
		{ field = "sourceRoot", value = "wrong", code = "SOURCE_ROOT_MISMATCH" },
	}
	for _, fixture in failureFixtures do
		local evidence = readiness()
		evidence[fixture.field] = fixture.value
		local result = Resolver.resolve("test", { privateReadiness = evidence })
		local code = if result.error then result.error.code else nil
		h:equal(code, fixture.code)
	end
	for countName in readiness().contentCounts do
		local evidence = readiness()
		evidence.contentCounts[countName] += 1
		local result = Resolver.resolve("test", { privateReadiness = evidence })
		local code = if result.error then result.error.code else nil
		h:equal(code, "CONTENT_COUNT_MISMATCH")
	end
	local digestEvidence = readiness()
	digestEvidence.declaredDigest = "declared"
	digestEvidence.verifiedDigest = "different"
	local digestResult = Resolver.resolve("test", { privateReadiness = digestEvidence })
	local digestCode = if digestResult.error then digestResult.error.code else nil
	h:equal(digestCode, "SOURCE_DIGEST_MISMATCH")

	local projected =
		Resolver.clientSafeStatus(Resolver.resolve("test", { privateReadiness = readiness() }))
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
