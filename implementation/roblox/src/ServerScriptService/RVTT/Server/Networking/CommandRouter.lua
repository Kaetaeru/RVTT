--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Envelope = require(ReplicatedStorage.RVTT.Shared.Protocol.Envelope)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)

local CommandRouter = {}
CommandRouter.__index = CommandRouter

function CommandRouter.new(runtime, remotes, rateLimiter, roleResolver, projectionPublisher, diagnostics)
	return setmetatable({ runtime = runtime, remotes = remotes, rateLimiter = rateLimiter, roleResolver = roleResolver, projectionPublisher = projectionPublisher, diagnostics = diagnostics }, CommandRouter)
end

function CommandRouter:start()
	self.remotes.command.OnServerEvent:Connect(function(player, rawEnvelope)
		local key = tostring(player.UserId)
		if not self.rateLimiter:allow(key) then
			self.remotes.receipt:FireClient(player, Result.err("RATE_LIMITED", "error.security.rate_limited", true))
			return
		end
		local envelopeResult = Envelope.validateCommand(rawEnvelope)
		if not envelopeResult.ok then
			self.remotes.receipt:FireClient(player, envelopeResult)
			return
		end
		local envelope = envelopeResult.value
		self.remotes.receipt:FireClient(player, Result.ok({ commandId = envelope.commandId, status = "accepted" }))
		local context = {
			player = player,
			playerId = player.UserId,
			role = self.roleResolver(player),
			commandId = envelope.commandId,
			correlationId = envelope.correlationId,
		}
		local result = self.runtime:execute(context, envelope)
		self.remotes.receipt:FireClient(player, result)
		if result.ok then
			self.projectionPublisher:publishAll()
		else
			self.diagnostics:increment("command.failed")
		end
	end)
end

return CommandRouter
