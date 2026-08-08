--!strict

local BuiltinPackIndex = require(script.Parent.BuiltinPackIndex)

local RulePackageResolver = {}

local PRIVATE_PACKAGE_ID = "rvtt.test.rules.2024.integrated.ko"
local PUBLIC_PACKAGE_ID = "rvtt.core.rules"
local FALLBACK_REASON = "INTEGRATED_TEST_PACK_UNAVAILABLE"
local PRIVATE_PROFILES = {
	development = true,
	test = true,
	["studio-acceptance"] = true,
}
local PUBLIC_PROFILES = {
	public = true,
	release = true,
	artifact = true,
}
local EXPECTED_COUNTS = {
	classes = 12,
	subclasses = 48,
	backgrounds = 16,
	species = 10,
	feats = 75,
	spells = 391,
}

local function includes(values: { string }, expected: string): boolean
	for _, value in values do
		if value == expected then
			return true
		end
	end
	return false
end

local function rulePackagesForProfile(profile: string): { any }
	local matches = {}
	for _, pack in BuiltinPackIndex do
		if
			includes(pack.contentKinds, "rule-packs") and includes(pack.defaultProfiles, profile)
		then
			table.insert(matches, pack)
		end
	end
	return matches
end

local function failure(code: string): any
	return {
		ok = false,
		error = {
			code = code,
			message = "The requested rules profile is not ready.",
		},
	}
end

local function readinessFailure(evidence: any): string?
	if type(evidence) ~= "table" or evidence.bindingPresent ~= true then
		return "PRIVATE_SOURCE_MISSING"
	end
	if evidence.sourceBindingKey ~= "RVTT_PRIVATE_DND2024_KO_SOURCE" then
		return "SOURCE_BINDING_MISMATCH"
	end
	if evidence.revision ~= "d3d574725e0ecdfd05cb69fa32cf66196e3a8ee4" then
		return "SOURCE_REVISION_MISMATCH"
	end
	if evidence.sourceRoot ~= "10-RULEBOOKS/integrated-2024" then
		return "SOURCE_ROOT_MISMATCH"
	end
	if type(evidence.contentCounts) ~= "table" then
		return "CONTENT_COUNT_MISMATCH"
	end
	for name, expected in EXPECTED_COUNTS do
		if evidence.contentCounts[name] ~= expected then
			return "CONTENT_COUNT_MISMATCH"
		end
	end
	local declaredDigest = evidence.declaredDigest
	local verifiedDigest = evidence.verifiedDigest
	if declaredDigest ~= nil or verifiedDigest ~= nil then
		if
			type(declaredDigest) ~= "string"
			or declaredDigest == ""
			or type(verifiedDigest) ~= "string"
			or verifiedDigest == ""
			or declaredDigest ~= verifiedDigest
		then
			return "SOURCE_DIGEST_MISMATCH"
		end
	end
	return nil
end

local function status(profile: string, packageId: string, fallbackActive: boolean): any
	return {
		activeProfile = profile,
		basePackageId = packageId,
		fallbackActive = fallbackActive,
		fallbackReasonCode = if fallbackActive then FALLBACK_REASON else nil,
		attributionRequired = true,
	}
end

function RulePackageResolver.resolve(profile: string, options: any?): any
	if not PRIVATE_PROFILES[profile] and not PUBLIC_PROFILES[profile] then
		return failure("UNKNOWN_PROFILE")
	end

	local matches = rulePackagesForProfile(profile)
	if #matches ~= 1 then
		return failure("RULE_PROFILE_AMBIGUOUS")
	end

	if PUBLIC_PROFILES[profile] then
		local package = matches[1]
		if
			package.packageId ~= PUBLIC_PACKAGE_ID
			or package.publicBuildAllowed ~= true
			or package.clientExportAllowed ~= true
			or package.ownerOnly == true
		then
			return failure("PUBLIC_PROFILE_NOT_SAFE")
		end
		return { ok = true, value = status(profile, PUBLIC_PACKAGE_ID, false) }
	end

	if matches[1].packageId ~= PRIVATE_PACKAGE_ID then
		return failure("PRIVATE_PROFILE_PACKAGE_MISMATCH")
	end
	local safeOptions = if type(options) == "table" then options else {}
	local readinessCode = readinessFailure(safeOptions.privateReadiness)
	if readinessCode ~= nil then
		if safeOptions.allowSrdFallback == true then
			return { ok = true, value = status(profile, PUBLIC_PACKAGE_ID, true) }
		end
		return failure(readinessCode)
	end

	return { ok = true, value = status(profile, PRIVATE_PACKAGE_ID, false) }
end

function RulePackageResolver.clientSafeStatus(result: any): any
	if type(result) ~= "table" or result.ok ~= true or type(result.value) ~= "table" then
		return nil
	end
	local value = result.value
	return {
		activeProfile = value.activeProfile,
		basePackageId = value.basePackageId,
		fallbackActive = value.fallbackActive == true,
		fallbackReasonCode = value.fallbackReasonCode,
		attributionRequired = value.attributionRequired == true,
	}
end

return RulePackageResolver
