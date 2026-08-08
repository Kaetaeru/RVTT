--!strict

local BuiltinPackIndex = require(script.Parent.BuiltinPackIndex)
local Validator = require(script.Parent.AssetRegistryValidator)
local ClientAssetViewBuilder = require(script.Parent.ClientAssetViewBuilder)

local AssetPackageRegistry = {}

function AssetPackageRegistry.get(packageId: string): any?
	for _, pack in BuiltinPackIndex do
		if pack.packageId == packageId then
			return pack.assetRegistry
		end
	end
	return nil
end

function AssetPackageRegistry.validate(packageId: string): any
	local package = AssetPackageRegistry.get(packageId)
	if package == nil then
		return {
			ok = false,
			errors = { "package is not a registered built-in asset package: " .. packageId },
		}
	end
	return Validator.validatePackage(
		package.sourceIdentity,
		package.manifest,
		package.assets,
		package.profile
	)
end

function AssetPackageRegistry.clientSafeView(packageId: string): { { [string]: any } }
	local package = AssetPackageRegistry.get(packageId)
	if package == nil then
		return {}
	end
	local validation = Validator.validatePackage(
		package.sourceIdentity,
		package.manifest,
		package.assets,
		package.profile
	)
	if not validation.ok then
		return {}
	end
	return ClientAssetViewBuilder.project(package.manifest, package.assets)
end

return AssetPackageRegistry
