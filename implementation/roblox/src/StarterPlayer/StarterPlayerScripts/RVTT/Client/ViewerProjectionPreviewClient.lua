--!strict

local ViewerProjectionPreviewClient = {}
ViewerProjectionPreviewClient.__index = ViewerProjectionPreviewClient

function ViewerProjectionPreviewClient.new(remote: RemoteFunction, replica: any): any
	return setmetatable({
		remote = remote,
		replica = replica,
		generation = 0,
		destroyed = false,
	}, ViewerProjectionPreviewClient)
end

function ViewerProjectionPreviewClient:invalidate()
	self.generation += 1
end

function ViewerProjectionPreviewClient:request(targetUserId: number, callback: (any) -> ())
	self.generation += 1
	local generation = self.generation
	local epoch = self.replica.epoch
	local revision = self.replica.revision
	task.spawn(function()
		local succeeded, result = pcall(function()
			return self.remote:InvokeServer({ targetUserId = targetUserId })
		end)
		if self.destroyed or generation ~= self.generation then
			return
		end
		if not succeeded then
			callback({ ok = false, stale = false, error = { code = "TRANSPORT_ERROR" } })
			return
		end
		if type(result) ~= "table" or result.ok ~= true then
			callback(result)
			return
		end
		local value = result.value
		local stale = type(value) ~= "table"
			or type(value.target) ~= "table"
			or value.target.userId ~= targetUserId
			or value.authorityEpoch ~= epoch
			or value.revision < revision
			or self.replica.epoch ~= value.authorityEpoch
			or self.replica.revision > value.revision
		callback({ ok = true, stale = stale, value = value })
	end)
	return generation
end

function ViewerProjectionPreviewClient:destroy()
	self.destroyed = true
	self:invalidate()
end

return ViewerProjectionPreviewClient
