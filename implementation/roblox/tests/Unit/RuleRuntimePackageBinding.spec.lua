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

return function(h: any)
	local ServerStorage = game:GetService("ServerStorage")
	local Content = ServerStorage.RVTT.Content
	local Binding = require(Content.RuleRuntimePackageBinding)
	local BuiltinPackIndex = require(Content.BuiltinPackIndex)
	local privateAuthority = packageById(BuiltinPackIndex, "rvtt.test.rules.2024.integrated.ko")
	local ownerUserId = 424242

	local readiness = {
		bindingPresent = true,
		sourceBindingKey = privateAuthority.sourceBindingKey,
		revision = privateAuthority.version,
		sourceRoot = privateAuthority.sourceRoot,
		verifiedDigest = privateAuthority.expectedSourceDigest,
		contentCounts = copy(privateAuthority.expectedContentCounts),
		authorizedUserIds = { ownerUserId },
	}
	local privatePackage = {
		schemaVersion = 1,
		packageId = privateAuthority.packageId,
		version = privateAuthority.version,
		locale = "ko-KR",
		license = {
			licenseId = "PRIVATE-USE-ONLY",
			attributionRequired = true,
			attributionText = "private fixture",
		},
		modules = {},
		chunks = {},
	}
	local exactBinding = {
		readiness = readiness,
		package = privatePackage,
	}

	for _, profile in { "development", "test", "studio-acceptance" } do
		local resolved = Binding.resolveProfileWithBinding(profile, exactBinding)
		h:expect(resolved.ok, profile .. " resolves with an exact runtime binding")
		h:equal(
			resolved.value.basePackageId,
			"rvtt.test.rules.2024.integrated.ko",
			profile .. " selects the private integrated package"
		)
		local provided =
			Binding.packageForIdWithBinding(resolved.value.basePackageId, profile, exactBinding)
		h:expect(provided == privatePackage, profile .. " provider returns the injected package")
		h:expect(
			Binding.viewerCanAccessProfileWithBinding(profile, ownerUserId, exactBinding),
			profile .. " authorizes the explicit owner user"
		)
		h:expect(
			not Binding.viewerCanAccessProfileWithBinding(profile, ownerUserId + 1, exactBinding),
			profile .. " denies an unlisted user without disclosure"
		)
	end

	local missing = Binding.resolveProfileWithBinding("development", nil)
	local missingCode = if missing.error then missing.error.code else nil
	h:equal(
		missingCode,
		"PRIVATE_SOURCE_MISSING",
		"private profile remains fail closed without binding"
	)
	h:equal(
		Binding.packageForIdWithBinding("rvtt.test.rules.2024.integrated.ko", "development", nil),
		nil,
		"missing binding never yields a private package"
	)
	h:expect(
		not Binding.viewerCanAccessProfileWithBinding("development", ownerUserId, nil),
		"missing binding never authorizes a private viewer"
	)

	local explicitFallback =
		Binding.resolveProfileWithBinding("development", nil, { allowSrdFallback = true })
	h:expect(explicitFallback.ok, "explicit runtime fallback resolves without private binding")
	h:equal(explicitFallback.value.basePackageId, "rvtt.core.rules")
	h:expect(
		explicitFallback.value.fallbackActive == true,
		"runtime fallback status remains visible"
	)
	h:equal(explicitFallback.value.fallbackReasonCode, "INTEGRATED_TEST_PACK_UNAVAILABLE")
	local fallbackPackage = Binding.packageForIdWithBinding(
		"rvtt.core.rules",
		"development",
		nil,
		{ allowSrdFallback = true }
	)
	h:expect(fallbackPackage ~= nil, "explicit runtime fallback provides the SRD package")
	h:equal(fallbackPackage.packageId, "rvtt.core.rules")
	h:expect(
		Binding.viewerCanAccessProfileWithBinding(
			"development",
			ownerUserId + 1,
			nil,
			{ allowSrdFallback = true }
		),
		"SRD fallback does not retain the private owner allowlist"
	)
	h:equal(
		Binding.packageForIdWithBinding(
			"rvtt.test.rules.2024.integrated.ko",
			"development",
			nil,
			{ allowSrdFallback = true }
		),
		nil,
		"explicit fallback cannot provide the private package"
	)

	local missingAccessBinding = copy(exactBinding)
	missingAccessBinding.readiness.authorizedUserIds = nil
	local missingAccess = Binding.resolveProfileWithBinding("test", missingAccessBinding)
	local missingAccessCode = if missingAccess.error then missingAccess.error.code else nil
	h:equal(
		missingAccessCode,
		"PRIVATE_RULE_ACCESS_MISSING",
		"private profile requires explicit viewer access"
	)

	local invalidAccessBinding = copy(exactBinding)
	invalidAccessBinding.readiness.authorizedUserIds = { 0 }
	local invalidAccess = Binding.resolveProfileWithBinding("test", invalidAccessBinding)
	local invalidAccessCode = if invalidAccess.error then invalidAccess.error.code else nil
	h:equal(
		invalidAccessCode,
		"PRIVATE_RULE_ACCESS_INVALID",
		"invalid private viewer id is rejected"
	)

	local staleReadinessBinding = copy(exactBinding)
	staleReadinessBinding.readiness.revision = "stale-revision"
	local staleReadiness = Binding.resolveProfileWithBinding("test", staleReadinessBinding)
	local staleReadinessCode = if staleReadiness.error then staleReadiness.error.code else nil
	h:equal(staleReadinessCode, "SOURCE_REVISION_MISMATCH", "stale readiness is rejected")
	h:expect(
		Binding.viewerCanAccessProfileWithBinding("test", ownerUserId, staleReadinessBinding),
		"authorized owner remains eligible to receive the stale-readiness diagnostic"
	)
	h:expect(
		not Binding.viewerCanAccessProfileWithBinding(
			"test",
			ownerUserId + 1,
			staleReadinessBinding
		),
		"unlisted viewer remains denied even when private readiness is stale"
	)

	local staleDigestBinding = copy(exactBinding)
	staleDigestBinding.readiness.verifiedDigest = "stale-digest"
	local staleDigest = Binding.resolveProfileWithBinding("test", staleDigestBinding)
	local staleDigestCode = if staleDigest.error then staleDigest.error.code else nil
	h:equal(staleDigestCode, "SOURCE_DIGEST_MISMATCH", "stale source tree is rejected")

	local wrongPackageBinding = copy(exactBinding)
	wrongPackageBinding.package.packageId = "rvtt.core.rules"
	local wrongPackage = Binding.resolveProfileWithBinding("test", wrongPackageBinding)
	local wrongPackageCode = if wrongPackage.error then wrongPackage.error.code else nil
	h:equal(wrongPackageCode, "PRIVATE_RULE_PACKAGE_MISMATCH", "wrong package identity is rejected")

	local stalePackageBinding = copy(exactBinding)
	stalePackageBinding.package.version = "stale-package-revision"
	local stalePackage = Binding.resolveProfileWithBinding("test", stalePackageBinding)
	local stalePackageCode = if stalePackage.error then stalePackage.error.code else nil
	h:equal(stalePackageCode, "PRIVATE_RULE_PACKAGE_MISMATCH", "stale imported package is rejected")

	local malformedPackageBinding = copy(exactBinding)
	malformedPackageBinding.package.chunks = nil
	local malformedPackage = Binding.resolveProfileWithBinding("test", malformedPackageBinding)
	local malformedPackageCode = if malformedPackage.error then malformedPackage.error.code else nil
	h:equal(
		malformedPackageCode,
		"PRIVATE_RULE_PACKAGE_MISMATCH",
		"package body shape is validated"
	)

	local publicResolved = Binding.resolveProfileWithBinding("public", wrongPackageBinding)
	h:expect(publicResolved.ok, "public profile does not depend on private binding state")
	h:equal(publicResolved.value.basePackageId, "rvtt.core.rules")
	local publicPackage =
		Binding.packageForIdWithBinding("rvtt.core.rules", "public", wrongPackageBinding)
	h:expect(publicPackage ~= nil, "public provider remains available")
	h:equal(publicPackage.packageId, "rvtt.core.rules")
	h:expect(
		Binding.viewerCanAccessProfileWithBinding("public", ownerUserId + 1, wrongPackageBinding),
		"public profile does not apply the private owner allowlist"
	)
	h:equal(
		Binding.packageForIdWithBinding(
			"rvtt.test.rules.2024.integrated.ko",
			"public",
			exactBinding
		),
		nil,
		"public profile cannot request the private package"
	)

	local fakeStorage = Instance.new("Folder")
	local loaded, loadError = Binding.loadRuntimeBinding(fakeStorage)
	h:equal(loaded, nil, "runtime loader requires the injected server-only root")
	h:equal(loadError, "PRIVATE_SOURCE_MISSING")
	local incompleteRoot = Instance.new("Folder")
	incompleteRoot.Name = Binding.RUNTIME_BINDING_ROOT_NAME
	incompleteRoot.Parent = fakeStorage
	local incomplete, incompleteError = Binding.loadRuntimeBinding(fakeStorage)
	h:equal(incomplete, nil, "runtime loader rejects incomplete injected roots")
	h:equal(incompleteError, "PRIVATE_SOURCE_MISSING")
	fakeStorage:Destroy()
end
