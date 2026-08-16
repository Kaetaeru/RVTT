--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)

local ViewerProjectionQuery = {}
ViewerProjectionQuery.__index = ViewerProjectionQuery

local REQUEST_INTERVAL_SECONDS = 0.2

function ViewerProjectionQuery.new(
	runtime: any,
	remotes: any,
	roleResolver: any,
	preview: any,
	clock: (() -> number)?
): any
	return setmetatable({
		runtime = runtime,
		remotes = remotes,
		roleResolver = roleResolver,
		preview = preview,
		clock = clock or os.clock,
		lastRequestByUserId = {},
	}, ViewerProjectionQuery)
end

function ViewerProjectionQuery:start()
	self.remotes.viewerProjectionPreview.OnServerInvoke = function(player: Player, request: any)
		if self.roleResolver(player) ~= "dm" then
			return Result.err("UNAUTHORIZED", "error.command.unauthorized", false)
		end
		local targetUserId = if type(request) == "table" then request.targetUserId else nil
		if type(targetUserId) ~= "number" or targetUserId % 1 ~= 0 or targetUserId <= 0 then
			return Result.err("VALIDATION_FAILED", "error.command.validation_failed", false)
		end

		local now = self.clock()
		local lastRequest = self.lastRequestByUserId[player.UserId]
		if type(lastRequest) == "number" and now - lastRequest < REQUEST_INTERVAL_SECONDS then
			return Result.err("RATE_LIMITED", "error.command.rate_limited", true)
		end
		self.lastRequestByUserId[player.UserId] = now
		return self.preview.build(self.runtime:snapshot(), targetUserId)
	end
end

return ViewerProjectionQuery
