--!strict

local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(windowSeconds: number, maximum: number)
	return setmetatable({ windowSeconds = windowSeconds, maximum = maximum, buckets = {} }, RateLimiter)
end

function RateLimiter:allow(key: string): boolean
	local now = os.clock()
	local bucket = self.buckets[key]
	if bucket == nil or now - bucket.startedAt >= self.windowSeconds then
		self.buckets[key] = { startedAt = now, count = 1 }
		return true
	end
	if bucket.count >= self.maximum then
		return false
	end
	bucket.count += 1
	return true
end

function RateLimiter:clear(key: string)
	self.buckets[key] = nil
end

return RateLimiter
