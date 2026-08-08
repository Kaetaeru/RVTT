--!strict

export type PackageIdentity = {
	packageId: string,
	version: string,
	assetSetDigest: string,
}

export type PackageManifest = PackageIdentity & {
	clientExportAllowed: boolean,
}

export type ValidationProfile = {
	forbiddenPayloadClasses: { [string]: boolean },
}

export type AssetRecord = {
	assetId: string,
	stableKey: string,
	packageId: string,
	version: string,
	kind: string,
	displayNameKey: string,
	sourceContentHash: string,
	runtimeContentAddress: string,
	publishedAssetId: string?,
	thumbnailAssetId: string,
	bounds: { [string]: any }?,
	pivot: { [string]: any }?,
	placementProfile: { [string]: any }?,
	collisionProfile: { [string]: any }?,
	navigationProfile: { [string]: any }?,
	interactionCapabilities: { string },
	performanceBudget: { [string]: number },
	dependencies: { string },
	rights: { [string]: any },
	provenance: { [string]: any },
	clientExportAllowed: boolean,
	sourcePayloadClasses: { string }?,
	rigProfile: { [string]: any }?,
	animationProfile: { [string]: any }?,
	cameraFocus: { [string]: any }?,
	interactionSockets: { any }?,
	stateVariants: { any }?,
	volumeProfile: { [string]: any }?,
}

export type ValidationResult = {
	ok: boolean,
	errors: { string },
}

local SPATIAL_KINDS = {
	["token-prefab"] = true,
	["prop-prefab"] = true,
	["tile-prefab"] = true,
	["volume-prefab"] = true,
}

local SUPPORTED_KINDS = {
	["token-prefab"] = true,
	["prop-prefab"] = true,
	["tile-prefab"] = true,
	["volume-prefab"] = true,
	material = true,
	vfx = true,
	animation = true,
	["ui-icon"] = true,
	["ui-texture"] = true,
	["ui-gizmo"] = true,
	["ui-thumbnail"] = true,
}

local function hasString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

local function addRequiredString(errors: { string }, asset: AssetRecord, field: string)
	if not hasString((asset :: any)[field]) then
		table.insert(errors, asset.assetId .. ": missing " .. field)
	end
end

local function validateBudget(errors: { string }, asset: AssetRecord)
	local budget = asset.performanceBudget
	if type(budget) ~= "table" then
		table.insert(errors, asset.assetId .. ": missing performanceBudget")
		return
	end
	for _, field in { "instances", "triangles", "textureMemoryKb" } do
		local value = budget[field]
		if type(value) ~= "number" or value < 0 or value ~= value or value == math.huge then
			table.insert(errors, asset.assetId .. ": invalid performanceBudget." .. field)
		end
	end
end

local function validateRightsAndProvenance(errors: { string }, asset: AssetRecord)
	local rights = asset.rights
	if
		type(rights) ~= "table"
		or not hasString(rights.licenseId)
		or not hasString(rights.status)
		or type(rights.redistributable) ~= "boolean"
	then
		table.insert(errors, asset.assetId .. ": missing rights metadata")
	end
	local provenance = asset.provenance
	if
		type(provenance) ~= "table"
		or not hasString(provenance.sourceType)
		or not hasString(provenance.sourceReference)
		or not hasString(provenance.sourceRevision)
	then
		table.insert(errors, asset.assetId .. ": missing provenance metadata")
	end
end

local function validateKindMetadata(errors: { string }, asset: AssetRecord)
	if SPATIAL_KINDS[asset.kind] then
		if type(asset.bounds) ~= "table" then
			table.insert(errors, asset.assetId .. ": missing bounds")
		end
		if type(asset.pivot) ~= "table" then
			table.insert(errors, asset.assetId .. ": missing pivot")
		end
		if type(asset.placementProfile) ~= "table" then
			table.insert(errors, asset.assetId .. ": missing placementProfile")
		end
		if type(asset.collisionProfile) ~= "table" then
			table.insert(errors, asset.assetId .. ": missing collisionProfile")
		end
		if type(asset.navigationProfile) ~= "table" then
			table.insert(errors, asset.assetId .. ": missing navigationProfile")
		end
	end
	if asset.kind == "token-prefab" then
		local placement = asset.placementProfile
		if type(asset.pivot) ~= "table" or asset.pivot.mode ~= "feet" then
			table.insert(errors, asset.assetId .. ": token pivot must use feet mode")
		end
		if
			type(placement) ~= "table"
			or type(placement.footprint) ~= "table"
			or type(placement.selectionBounds) ~= "table"
		then
			table.insert(
				errors,
				asset.assetId .. ": token footprint and selectionBounds are required"
			)
		end
		if type(asset.rigProfile) ~= "table" then
			table.insert(errors, asset.assetId .. ": token rigProfile is required")
		end
		if type(asset.animationProfile) ~= "table" then
			table.insert(errors, asset.assetId .. ": token animationProfile is required")
		end
		if type(asset.cameraFocus) ~= "table" then
			table.insert(errors, asset.assetId .. ": token cameraFocus is required")
		end
	elseif asset.kind == "prop-prefab" then
		if
			type(asset.placementProfile) ~= "table" or not hasString(asset.placementProfile.surface)
		then
			table.insert(errors, asset.assetId .. ": prop placement surface is required")
		end
		if type(asset.interactionSockets) ~= "table" then
			table.insert(errors, asset.assetId .. ": prop interactionSockets are required")
		end
		if type(asset.stateVariants) ~= "table" then
			table.insert(errors, asset.assetId .. ": prop stateVariants are required")
		end
	elseif asset.kind == "tile-prefab" then
		local placement = asset.placementProfile
		if
			type(placement) ~= "table"
			or type(placement.cell) ~= "table"
			or type(placement.snap) ~= "table"
			or type(placement.edgeConnectors) ~= "table"
		then
			table.insert(
				errors,
				asset.assetId .. ": tile cell, snap, and edgeConnectors are required"
			)
		end
		if
			type(asset.navigationProfile) ~= "table"
			or not hasString(asset.navigationProfile.walkability)
		then
			table.insert(errors, asset.assetId .. ": tile walkability is required")
		end
	elseif asset.kind == "volume-prefab" then
		local volume = asset.volumeProfile
		if
			type(volume) ~= "table"
			or not hasString(volume.effectKind)
			or not hasString(volume.replicationPolicy)
		then
			table.insert(
				errors,
				asset.assetId .. ": volume effectKind and replicationPolicy are required"
			)
		end
	end
end

local function validateDependencies(errors: { string }, assetsById: { [string]: AssetRecord })
	local marks: { [string]: string } = {}
	local function visit(assetId: string)
		if marks[assetId] == "visiting" then
			table.insert(errors, assetId .. ": dependency cycle")
			return
		end
		if marks[assetId] == "done" then
			return
		end
		marks[assetId] = "visiting"
		local asset = assetsById[assetId]
		for _, dependencyId in asset.dependencies do
			if assetsById[dependencyId] == nil then
				table.insert(errors, assetId .. ": invalid dependency " .. dependencyId)
			else
				visit(dependencyId)
			end
		end
		marks[assetId] = "done"
	end
	for assetId in assetsById do
		visit(assetId)
	end
end

local AssetRegistryValidator = {}

function AssetRegistryValidator.validatePackage(
	sourceIdentity: PackageIdentity,
	manifest: PackageManifest,
	assets: { AssetRecord },
	profile: ValidationProfile
): ValidationResult
	local errors: { string } = {}
	for _, field in { "packageId", "version", "assetSetDigest" } do
		if (sourceIdentity :: any)[field] ~= (manifest :: any)[field] then
			table.insert(errors, "source/server identity drift: " .. field)
		end
	end

	local assetsById: { [string]: AssetRecord } = {}
	local stableKeys: { [string]: boolean } = {}
	for _, asset in assets do
		addRequiredString(errors, asset, "assetId")
		addRequiredString(errors, asset, "stableKey")
		addRequiredString(errors, asset, "kind")
		addRequiredString(errors, asset, "displayNameKey")
		addRequiredString(errors, asset, "sourceContentHash")
		addRequiredString(errors, asset, "runtimeContentAddress")
		addRequiredString(errors, asset, "thumbnailAssetId")
		if not SUPPORTED_KINDS[asset.kind] then
			table.insert(errors, asset.assetId .. ": unsupported asset kind")
		end
		if type(asset.clientExportAllowed) ~= "boolean" then
			table.insert(errors, asset.assetId .. ": clientExportAllowed must be explicit")
		end
		if asset.packageId ~= manifest.packageId or asset.version ~= manifest.version then
			table.insert(errors, asset.assetId .. ": package identity mismatch")
		end
		if assetsById[asset.assetId] ~= nil then
			table.insert(errors, asset.assetId .. ": duplicate assetId")
		else
			assetsById[asset.assetId] = asset
		end
		if stableKeys[asset.stableKey] then
			table.insert(errors, asset.assetId .. ": duplicate stableKey")
		else
			stableKeys[asset.stableKey] = true
		end
		validateRightsAndProvenance(errors, asset)
		validateBudget(errors, asset)
		validateKindMetadata(errors, asset)
		local payloadClasses: { string } = asset.sourcePayloadClasses or {}
		for _, className in payloadClasses do
			if profile.forbiddenPayloadClasses[className] then
				table.insert(errors, asset.assetId .. ": executable payload class " .. className)
			end
		end
	end
	validateDependencies(errors, assetsById)
	return {
		ok = #errors == 0,
		errors = errors,
	}
end

return AssetRegistryValidator
