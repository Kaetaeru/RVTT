--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)

local RuleReaderQuery = {}
RuleReaderQuery.__index = RuleReaderQuery

local REQUEST_INTERVAL_SECONDS = 0.05

function RuleReaderQuery.new(
	remote: RemoteFunction,
	roleResolver: (Player) -> string,
	service: any,
	resolveProfile: () -> any,
	packageProvider: (string) -> any?,
	clock: (() -> number)?
): any
	return setmetatable({
		remote = remote,
		roleResolver = roleResolver,
		service = service,
		resolveProfile = resolveProfile,
		packageProvider = packageProvider,
		clock = clock or os.clock,
		lastRequestByUserId = {},
	}, RuleReaderQuery)
end

local function validationFailure(): any
	return Result.err("VALIDATION_FAILED", "error.command.validation_failed", false)
end

function RuleReaderQuery:_activePackage(): (any?, any)
	local profileResult = self.resolveProfile()
	if type(profileResult) ~= "table" or profileResult.ok ~= true then
		if type(profileResult) == "table" and profileResult.ok == false then
			return nil, profileResult
		end
		return nil, Result.err("RULE_PROFILE_UNAVAILABLE", "error.rules.profile_unavailable", true)
	end
	local status = profileResult.value
	if type(status) ~= "table" or type(status.basePackageId) ~= "string" then
		return nil, Result.err("RULE_PROFILE_UNAVAILABLE", "error.rules.profile_unavailable", true)
	end
	local package = self.packageProvider(status.basePackageId)
	if package == nil then
		return nil, Result.err(
			"RULE_PACKAGE_UNAVAILABLE",
			"error.rules.package_unavailable",
			true,
			{ basePackageId = status.basePackageId }
		)
	end
	return package, Result.ok(status)
end

function RuleReaderQuery:_handle(player: Player, request: any): any
	if type(request) ~= "table" or type(request.action) ~= "string" then
		return validationFailure()
	end
	local package, profileResult = self:_activePackage()
	if package == nil then
		return profileResult
	end
	local viewer = {
		userId = player.UserId,
		role = self.roleResolver(player),
	}
	local profileStatus = profileResult.value
	if request.action == "manifest" then
		return Result.ok(self.service.manifest(package, viewer, profileStatus))
	end
	if request.action == "search" then
		if type(request.query) ~= "string" or #request.query > 160 then
			return validationFailure()
		end
		return Result.ok(self.service.search(package, viewer, request.query, request.limit))
	end
	if request.action == "open" then
		local value, code = self.service.open(package, viewer, request.uri)
		if value == nil then
			return Result.err(code or "RULE_LINK_UNAVAILABLE", "error.rules.link_unavailable", false)
		end
		return Result.ok(value)
	end
	if request.action == "chunk" then
		local value, code = self.service.chunk(package, viewer, request.chunkId)
		if value == nil then
			return Result.err(code or "RULE_CHUNK_UNAVAILABLE", "error.rules.chunk_unavailable", false)
		end
		return Result.ok(value)
	end
	return validationFailure()
end

function RuleReaderQuery:start()
	self.remote.OnServerInvoke = function(player: Player, request: any)
		local now = self.clock()
		local lastRequest = self.lastRequestByUserId[player.UserId]
		if type(lastRequest) == "number" and now - lastRequest < REQUEST_INTERVAL_SECONDS then
			return Result.err("RATE_LIMITED", "error.command.rate_limited", true)
		end
		self.lastRequestByUserId[player.UserId] = now
		return self:_handle(player, request)
	end
end

return RuleReaderQuery
