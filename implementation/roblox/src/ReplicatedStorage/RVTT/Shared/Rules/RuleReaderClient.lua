--!strict

local RuleReaderClient = {}
RuleReaderClient.__index = RuleReaderClient

function RuleReaderClient.new(remote: RemoteFunction): any
	return setmetatable({
		remote = remote,
		generation = 0,
		destroyed = false,
		manifestCache = nil,
		chunkCache = {},
	}, RuleReaderClient)
end

function RuleReaderClient:invalidate()
	self.generation += 1
	self.manifestCache = nil
	self.chunkCache = {}
end

function RuleReaderClient:_request(payload: any, callback: (any) -> ())
	self.generation += 1
	local generation = self.generation
	task.spawn(function()
		local succeeded, result = pcall(function()
			return self.remote:InvokeServer(payload)
		end)
		if self.destroyed or generation ~= self.generation then
			return
		end
		if not succeeded then
			callback({ ok = false, error = { code = "TRANSPORT_ERROR", retryable = true } })
			return
		end
		if type(result) ~= "table" then
			callback({ ok = false, error = { code = "INVALID_RESPONSE", retryable = true } })
			return
		end
		callback(result)
	end)
	return generation
end

function RuleReaderClient:manifest(callback: (any) -> ())
	if self.manifestCache ~= nil then
		callback({ ok = true, value = self.manifestCache, cached = true })
		return self.generation
	end
	return self:_request({ action = "manifest" }, function(result)
		if result.ok == true and type(result.value) == "table" then
			self.manifestCache = result.value
		end
		callback(result)
	end)
end

function RuleReaderClient:search(query: string, callback: (any) -> ())
	return self:_request({ action = "search", query = query, limit = 16 }, callback)
end

function RuleReaderClient:open(uri: string, callback: (any) -> ())
	return self:_request({ action = "open", uri = uri }, function(result)
		if result.ok == true and type(result.value) == "table" then
			local chunk = result.value.chunk
			if type(chunk) == "table" and type(chunk.id) == "string" then
				self.chunkCache[chunk.id] = chunk
			end
		end
		callback(result)
	end)
end

function RuleReaderClient:chunk(chunkId: string, callback: (any) -> ())
	local cached = self.chunkCache[chunkId]
	if cached ~= nil then
		callback({ ok = true, value = cached, cached = true })
		return self.generation
	end
	return self:_request({ action = "chunk", chunkId = chunkId }, function(result)
		if
			result.ok == true
			and type(result.value) == "table"
			and type(result.value.id) == "string"
		then
			self.chunkCache[result.value.id] = result.value
		end
		callback(result)
	end)
end

function RuleReaderClient:destroy()
	self.destroyed = true
	self:invalidate()
end

return RuleReaderClient
