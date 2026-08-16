--!strict

local function artifact(): any
	return {
		profile = "release",
		basePackageId = "rvtt.core.rules",
		packageIds = { "rvtt.core.rules" },
		files = {
			{
				path = "rules/srd-index.json",
				content = "rvtt-rule://rvtt.core.rules/combat/actions",
				metadata = { buildKind = "public" },
			},
		},
		ruleLinks = { "rvtt-rule://rvtt.core.rules/conditions/prone" },
		license = {
			packageId = "rvtt.core.rules",
			licenseId = "CC-BY-4.0",
			attributionRequired = true,
			attributionText = "SRD attribution fixture",
		},
	}
end

local function hasCode(result: any, expected: string): boolean
	for _, code in result.errors do
		if code == expected then
			return true
		end
	end
	return false
end

return function(h)
	local Content = game:GetService("ServerStorage").RVTT.Content
	local Gate = require(Content.ReleaseContentLeakGate)
	local privatePackage: any = nil
	for _, package in require(Content.BuiltinPackIndex) do
		if package.packageId == "rvtt.test.rules.2024.integrated.ko" then
			privatePackage = package
		end
	end
	h:expect(privatePackage ~= nil, "private package authority exists")

	h:expect(Gate.validate(artifact()).ok, "clean synthetic public artifact passes")

	local privatePackageArtifact = artifact()
	table.insert(privatePackageArtifact.packageIds, "rvtt.test.rules.2024.integrated.ko")
	h:expect(
		hasCode(Gate.validate(privatePackageArtifact), "PRIVATE_PACKAGE_PRESENT"),
		"private package is rejected"
	)

	for _, marker in
		{
			privatePackage.sourceRepository,
			privatePackage.sourceBindingKey,
			privatePackage.sourceRoot,
			privatePackage.version,
			"private-rule-chunk",
			"private-search-index",
			"private-snippet-cache",
		}
	do
		local fixture = artifact()
		fixture.files[1].content = marker
		h:expect(
			hasCode(Gate.validate(fixture), "PRIVATE_CONTENT_MARKER"),
			marker .. " is rejected"
		)
	end

	local metadata = artifact()
	metadata.files[1].metadata.sourceRevision = "private-revision"
	h:expect(
		hasCode(Gate.validate(metadata), "PRIVATE_SOURCE_METADATA"),
		"source revision metadata is rejected"
	)
	local credential = artifact()
	credential.files[1].metadata.credential = "synthetic-secret"
	h:expect(
		hasCode(Gate.validate(credential), "PRIVATE_SOURCE_METADATA"),
		"credential-like metadata is rejected"
	)

	local privateLink = artifact()
	privateLink.ruleLinks = { "rvtt-rule://rvtt.test.rules.2024.integrated.ko/classes/fighter" }
	h:expect(
		hasCode(Gate.validate(privateLink), "NON_PUBLIC_RULE_LINK"),
		"private rule anchor is rejected"
	)
	local missingLicense = artifact()
	missingLicense.license = nil
	h:expect(
		hasCode(Gate.validate(missingLicense), "SRD_ATTRIBUTION_REQUIRED"),
		"missing SRD attribution is rejected"
	)
	local wrongBase = artifact()
	wrongBase.basePackageId = "another.package"
	h:expect(
		hasCode(Gate.validate(wrongBase), "PUBLIC_BASE_PACKAGE_REQUIRED"),
		"public base is mandatory"
	)
end
