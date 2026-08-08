--!strict

local function copyVector(source: { [string]: any }?): { [string]: any }?
	if source == nil then
		return nil
	end
	return {
		x = source.x,
		y = source.y,
		z = source.z,
	}
end

local function copyStringArray(source: { string }): { string }
	local result = {}
	for _, value in source do
		table.insert(result, value)
	end
	return result
end

local function projectPlacement(source: { [string]: any }?): { [string]: any }?
	if source == nil then
		return nil
	end
	return {
		footprint = copyVector(source.footprint),
		selectionBounds = copyVector(source.selectionBounds),
		surface = source.surface,
	}
end

local ClientAssetViewBuilder = {}

function ClientAssetViewBuilder.project(
	manifest: { [string]: any },
	assets: { { [string]: any } }
): { { [string]: any } }
	local projected = {}
	if manifest.clientExportAllowed ~= true then
		return projected
	end
	for _, asset in assets do
		if asset.clientExportAllowed == true then
			local view: { [string]: any } = {
				assetId = asset.assetId,
				packageId = asset.packageId,
				version = asset.version,
				kind = asset.kind,
				displayNameKey = asset.displayNameKey,
				thumbnailAssetId = asset.thumbnailAssetId,
				bounds = copyVector(asset.bounds),
				pivot = {
					mode = if asset.pivot then asset.pivot.mode else nil,
					x = if asset.pivot then asset.pivot.x else nil,
					y = if asset.pivot then asset.pivot.y else nil,
					z = if asset.pivot then asset.pivot.z else nil,
				},
				placementProfile = projectPlacement(asset.placementProfile),
				collisionProfile = {
					mode = if asset.collisionProfile then asset.collisionProfile.mode else nil,
				},
				navigationProfile = {
					mode = if asset.navigationProfile then asset.navigationProfile.mode else nil,
				},
				interactionCapabilities = copyStringArray(asset.interactionCapabilities or {}),
				performanceBudget = {
					instances = asset.performanceBudget.instances,
					triangles = asset.performanceBudget.triangles,
					textureMemoryKb = asset.performanceBudget.textureMemoryKb,
				},
				rights = {
					licenseId = asset.rights.licenseId,
					attributionRequired = asset.rights.attributionRequired,
					attributionText = asset.rights.attributionText,
				},
			}
			if asset.publishedAssetId ~= nil then
				view.publishedAssetId = asset.publishedAssetId
			end
			table.insert(projected, view)
		end
	end
	return projected
end

return ClientAssetViewBuilder
