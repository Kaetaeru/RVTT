--!strict

local BuiltinPackIndex = require(script.Parent.BuiltinPackIndex)

local RulePackageResolver = {}

local PRIVATE_PACKAGE_ID = "rvtt.test.rules.2024.integrated.ko"
local PUBLIC_PACKAGE_ID = "rvtt.core.rules"
local FALLBACK_REASON = "INTEGRATED_TEST_PACK_UNAVAILABLE"

local function includes(values: { string }, expected: string): boolean
	for _, value in values do
		if value == expected then
			return true
		end
	end
	return false
end

local function rulePackagesForProfile(packageIndex: { any }, profile: string): { any }
	local matches = {}
	for _, pack in packageIndex do
		if
			includes(pack.contentKinds, "rule-packs") and includes(pack.defaultProfiles, profile)
		then
			table.insert(matches, pack)
		end
	end
	return matches
end

local function packageById(packageIndex: { any }, packageId: string): any?
	for _, package in packageIndex do
		if package.packageId == packageId then
			return package
		end
	end
	return nil
end

local function isPublicSafe(package: any): boolean
	return package.packageId == PUBLIC_PACKAGE_ID
		and package.publicBuildAllowed == true
		and package.clientExportAllowed == true
		and package.ownerOnly ~= true
		and package.redistributable == true
		and package.licenseId == "CC-BY-4.0"
		and package.attributionRequired == true
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

local function readinessFailure(package: any, evidence: any): string?
	if type(evidence) ~= "table" or evidence.bindingPresent ~= true then
		return "PRIVATE_SOURCE_MISSING"
	end
	if evidence.sourceBindingKey ~= package.sourceBindingKey then
		return "SOURCE_BINDING_MISMATCH"
	end
	if evidence.revision ~= package.version then
		return "SOURCE_REVISION_MISMATCH"
	end
	if evidence.sourceRoot ~= package.sourceRoot then
		return "SOURCE_ROOT_MISMATCH"
	end
	if
		type(package.expectedContentCounts) ~= "table"
		or type(evidence.contentCounts) ~= "table"
	then
		return "CONTENT_COUNT_MISMATCH"
	end
	for name, expected in package.expectedContentCounts do
		if evidence.contentCounts[name] ~= expected then
			return "CONTENT_COUNT_MISMATCH"
		end
	end
	local expectedDigest = package.expectedSourceDigest
	if expectedDigest ~= nil then
		if type(expectedDigest) ~= "string" or evidence.verifiedDigest ~= expectedDigest then
			return "SOURCE_DIGEST_MISMATCH"
		end
	end
	return nil
end

local function status(profile: string, package: any, fallbackActive: boolean): any
	return {
		activeProfile = profile,
		basePackageId = package.packageId,
		fallbackActive = fallbackActive,
		fallbackReasonCode = if fallbackActive then FALLBACK_REASON else nil,
		attributionRequired = package.attributionRequired == true,
	}
end

function RulePackageResolver.resolveWithIndex(
	packageIndex: { any },
	profile: string,
	options: any?
): any
	local matches = rulePackagesForProfile(packageIndex, profile)
	if #matches == 0 then
		return failure("UNKNOWN_PROFILE")
	end
	if #matches ~= 1 then
		return failure("RULE_PROFILE_AMBIGUOUS")
	end

	local package = matches[1]
	if package.publicBuildAllowed == true then
		if not isPublicSafe(package) then
			return failure("PUBLIC_PROFILE_NOT_SAFE")
		end
		return { ok = true, value = status(profile, package, false) }
	end

	if
		package.packageId ~= PRIVATE_PACKAGE_ID
		or package.clientExportAllowed ~= false
		or package.ownerOnly ~= true
		or package.failClosed ~= true
	then
		return failure("PRIVATE_PROFILE_PACKAGE_MISMATCH")
	end
	local safeOptions = if type(options) == "table" then options else {}
	local readinessCode = readinessFailure(package, safeOptions.privateReadiness)
	if readinessCode ~= nil then
		if safeOptions.allowSrdFallback == true then
			local publicPackage = packageById(packageIndex, PUBLIC_PACKAGE_ID)
			if publicPackage == nil or not isPublicSafe(publicPackage) then
				return failure("PUBLIC_FALLBACK_NOT_SAFE")
			end
			return { ok = true, value = status(profile, publicPackage, true) }
		end
		return failure(readinessCode)
	end

	return { ok = true, value = status(profile, package, false) }
end

function RulePackageResolver.resolve(profile: string, options: any?): any
	return RulePackageResolver.resolveWithIndex(BuiltinPackIndex, profile, options)
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
