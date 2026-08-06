--!strict

export type Bucket = {
	startedAt: number,
	count: number,
}

export type RateLimiter = {
	windowSeconds: number,
	maximum: number,
	buckets: { [string]: Bucket },
	allow: (self: RateLimiter, key: string) -> boolean,
	clear: (self: RateLimiter, key: string) -> (),
}

local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(windowSeconds: number, maximum: number): RateLimiter
	return setmetatable({
		windowSeconds = windowSeconds,
		maximum = maximum,
		buckets = {},
	}, RateLimiter) :: any
end

function RateLimiter.allow(self: RateLimiter, key: string): boolean
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

function RateLimiter.clear(self: RateLimiter, key: string)
	self.buckets[key] = nil
end

return RateLimiter
