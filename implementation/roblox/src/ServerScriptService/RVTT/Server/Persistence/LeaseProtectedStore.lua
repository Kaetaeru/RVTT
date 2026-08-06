--!strict

local LeaseProtectedStore = {}
LeaseProtectedStore.__index = LeaseProtectedStore

function LeaseProtectedStore.new(
	delegate: any,
	ownership: any,
	diagnostics: any,
	initialDocument: any
): any
	return setmetatable({
		delegate = delegate,
		ownership = ownership,
		diagnostics = diagnostics,
		initialDocument = initialDocument,
	}, LeaseProtectedStore)
end

function LeaseProtectedStore.load(self: any, key: string): any
	local verified = self.ownership:verifyRemote()
	if not verified.ok then
		self.diagnostics:increment("persistence.lease_blocked_load")
		return verified
	end
	local fenceResult = self.ownership:writeFence()
	if not fenceResult.ok then
		self.diagnostics:increment("persistence.lease_fence_unavailable")
		return fenceResult
	end
	return self.delegate:loadFenced(key, self.initialDocument, fenceResult.value)
end

function LeaseProtectedStore.save(self: any, key: string, value: any): any
	local verified = self.ownership:verifyRemote()
	if not verified.ok then
		self.diagnostics:increment("persistence.lease_blocked_save")
		return verified
	end
	local fenceResult = self.ownership:writeFence()
	if not fenceResult.ok then
		self.diagnostics:increment("persistence.lease_fence_unavailable")
		return fenceResult
	end
	return self.delegate:save(key, value, fenceResult.value)
end

return LeaseProtectedStore
