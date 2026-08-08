--!strict

local ServerStorage = game:GetService("ServerStorage")

local BuiltinPackIndex = require(script.Parent.BuiltinPackIndex)
local RulePackageResolver = require(script.Parent.RulePackageResolver)
local CoreRulesPackage = require(script.Parent.Packs["rvtt.core.rules"].RuleReaderPackage)

local RuleRuntimePackageBinding = {}

local PRIVATE_PACKAGE_ID = "rvtt.test.rules.2024.integrated.ko"
local RUNTIME_BINDING_ROOT_NAME = "RVTTPrivateRuleContent"
local READINESS_MODULE_NAME = "Readiness"
local PACKAGE_MODULE_NAME = "RuleReaderPackage"
local PRIVATE_PROFILES = {
	development = true,
	test = true,
	["studio-acceptance"] = true,
}

RuleRuntimePackageBinding.RUNTIME_BINDING_ROOT_NAME = RUNTIME_BINDING_ROOT_NAME
RuleRuntimePackageBinding.READINESS_MODULE_NAME = READINESS_MODULE_NAME
RuleRuntimePackageBinding.PACKAGE_MODULE_NAME = PACKAGE_MODULE_NAME

local function failure(code: string): any
	return {
		ok = false,
		error = {
			code = code,
			message = "The requested rules profile is not ready.",
		},
	}
end

local function resolverOptions(options: any?): any
	return {
		allowSrdFallback = type(options) == "table" and options.allowSrdFallback == true,
	}
end

local function privateAuthority(): any?
	for _, package in BuiltinPackIndex do
		if package.packageId == PRIVATE_PACKAGE_ID then
			return package
		end
	end
	return nil
end

local function validatePrivatePackage(package: any): string?
	local authority = privateAuthority()
	if authority == nil then
		return "PRIVATE_PACKAGE_AUTHORITY_MISSING"
	end
	if type(package) ~= "table" then
		return "PRIVATE_RULE_PACKAGE_MISMATCH"
	end
	if package.packageId ~= authority.packageId or package.version ~= authority.version then
		return "PRIVATE_RULE_PACKAGE_MISMATCH"
	end
	if type(package.modules) ~= "table" or type(package.chunks) ~= "table" then
		return "PRIVATE_RULE_PACKAGE_MISMATCH"
	end
	return nil
end

local function validateAuthorizedUserIds(readiness: any): string?
	if type(readiness) ~= "table" or type(readiness.authorizedUserIds) ~= "table" then
		return "PRIVATE_RULE_ACCESS_MISSING"
	end
	local count = 0
	local seen = {}
	for _, userId in readiness.authorizedUserIds do
		if type(userId) ~= "number" or userId <= 0 or userId % 1 ~= 0 then
			return "PRIVATE_RULE_ACCESS_INVALID"
		end
		if seen[userId] == true then
			return "PRIVATE_RULE_ACCESS_INVALID"
		end
		seen[userId] = true
		count += 1
	end
	if count == 0 then
		return "PRIVATE_RULE_ACCESS_MISSING"
	end
	return nil
end

local function userIsAuthorized(readiness: any, userId: number): boolean
	if validateAuthorizedUserIds(readiness) ~= nil then
		return false
	end
	for _, allowedUserId in readiness.authorizedUserIds do
		if allowedUserId == userId then
			return true
		end
	end
	return false
end

function RuleRuntimePackageBinding.loadRuntimeBinding(storage: Instance?): (any?, string?)
	local sourceStorage = storage or ServerStorage
	local root = sourceStorage:FindFirstChild(RUNTIME_BINDING_ROOT_NAME)
	if root == nil or not root:IsA("Folder") then
		return nil, "PRIVATE_SOURCE_MISSING"
	end
	local readinessModule = root:FindFirstChild(READINESS_MODULE_NAME)
	local packageModule = root:FindFirstChild(PACKAGE_MODULE_NAME)
	if
		readinessModule == nil
		or not readinessModule:IsA("ModuleScript")
		or packageModule == nil
		or not packageModule:IsA("ModuleScript")
	then
		return nil, "PRIVATE_SOURCE_MISSING"
	end
	local readinessOk, readiness = pcall(require, readinessModule)
	local packageOk, package = pcall(require, packageModule)
	if not readinessOk or not packageOk then
		return nil, "PRIVATE_SOURCE_MISSING"
	end
	if type(readiness) ~= "table" or type(package) ~= "table" then
		return nil, "PRIVATE_SOURCE_MISSING"
	end
	return {
		readiness = readiness,
		package = package,
	}, nil
end

function RuleRuntimePackageBinding.resolveProfileWithBinding(
	profile: string,
	binding: any?,
	options: any?
): any
	if PRIVATE_PROFILES[profile] ~= true then
		return RulePackageResolver.resolve(profile, {})
	end
	local safeOptions = resolverOptions(options)
	if type(binding) == "table" then
		safeOptions.privateReadiness = binding.readiness
	end
	local result = RulePackageResolver.resolve(profile, safeOptions)
	if type(result) ~= "table" or result.ok ~= true then
		return result
	end
	-- An explicit development/test fallback selects the public package and must not
	-- depend on private package or allowlist material that is unavailable by design.
	if result.value.basePackageId == CoreRulesPackage.packageId then
		return result
	end
	if type(binding) ~= "table" then
		return failure("PRIVATE_SOURCE_MISSING")
	end
	local accessError = validateAuthorizedUserIds(binding.readiness)
	if accessError ~= nil then
		return failure(accessError)
	end
	local packageError = validatePrivatePackage(binding.package)
	if packageError ~= nil then
		return failure(packageError)
	end
	return result
end

function RuleRuntimePackageBinding.resolveProfile(profile: string, options: any?): any
	if PRIVATE_PROFILES[profile] ~= true then
		return RulePackageResolver.resolve(profile, {})
	end
	local binding, loadError = RuleRuntimePackageBinding.loadRuntimeBinding()
	if binding == nil and loadError ~= "PRIVATE_SOURCE_MISSING" then
		return failure(loadError or "PRIVATE_SOURCE_MISSING")
	end
	return RuleRuntimePackageBinding.resolveProfileWithBinding(profile, binding, options)
end

function RuleRuntimePackageBinding.viewerCanAccessProfileWithBinding(
	profile: string,
	userId: number,
	binding: any?,
	options: any?
): boolean
	if PRIVATE_PROFILES[profile] ~= true then
		return true
	end
	local safeOptions = resolverOptions(options)
	if safeOptions.allowSrdFallback == true then
		local resolved = RuleRuntimePackageBinding.resolveProfileWithBinding(profile, binding, safeOptions)
		if
			type(resolved) == "table"
			and resolved.ok == true
			and resolved.value.basePackageId == CoreRulesPackage.packageId
		then
			return true
		end
	end
	-- Private viewer authorization is intentionally independent of source readiness.
	-- This lets an authorized owner receive a safe Revision/Count/Digest diagnostic
	-- while an unlisted viewer is rejected before RuleReaderQuery resolves the profile.
	if type(binding) ~= "table" then
		return false
	end
	return userIsAuthorized(binding.readiness, userId)
end

function RuleRuntimePackageBinding.viewerCanAccessProfile(
	profile: string,
	userId: number,
	options: any?
): boolean
	if PRIVATE_PROFILES[profile] ~= true then
		return true
	end
	local binding = select(1, RuleRuntimePackageBinding.loadRuntimeBinding())
	return RuleRuntimePackageBinding.viewerCanAccessProfileWithBinding(
		profile,
		userId,
		binding,
		options
	)
end

function RuleRuntimePackageBinding.packageForIdWithBinding(
	packageId: string,
	profile: string,
	binding: any?,
	options: any?
): any?
	local result = RuleRuntimePackageBinding.resolveProfileWithBinding(profile, binding, options)
	if type(result) ~= "table" or result.ok ~= true then
		return nil
	end
	if result.value.basePackageId ~= packageId then
		return nil
	end
	if packageId == CoreRulesPackage.packageId then
		return CoreRulesPackage
	end
	if packageId == PRIVATE_PACKAGE_ID and type(binding) == "table" then
		return binding.package
	end
	return nil
end

function RuleRuntimePackageBinding.packageForId(
	packageId: string,
	profile: string,
	options: any?
): any?
	if PRIVATE_PROFILES[profile] ~= true then
		return RuleRuntimePackageBinding.packageForIdWithBinding(packageId, profile, nil, options)
	end
	local binding = select(1, RuleRuntimePackageBinding.loadRuntimeBinding())
	return RuleRuntimePackageBinding.packageForIdWithBinding(packageId, profile, binding, options)
end

return RuleRuntimePackageBinding
