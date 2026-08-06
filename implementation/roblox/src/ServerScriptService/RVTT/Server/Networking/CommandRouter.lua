--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Envelope = require(ReplicatedStorage.RVTT.Shared.Protocol.Envelope)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)

local CommandRouter = {}
CommandRouter.__index = CommandRouter

type PlayerIdResolver = (Player) -> number
type CommandGuard = (any, any) -> any

local function defaultPlayerIdResolver(player: Player): number
	return player.UserId
end

function CommandRouter.new(
	runtime,
	remotes,
	rateLimiter,
	roleResolver,
	projectionPublisher,
	diagnostics,
	playerIdResolver: PlayerIdResolver?,
	commandGuard: CommandGuard?
)
	return setmetatable({
		runtime = runtime,
		remotes = remotes,
		rateLimiter = rateLimiter,
		roleResolver = roleResolver,
		projectionPublisher = projectionPublisher,
		diagnostics = diagnostics,
		playerIdResolver = playerIdResolver or defaultPlayerIdResolver,
		commandGuard = commandGuard,
	}, CommandRouter)
end

local function receipt(commandId: string?, phase: string, result)
	return {
		commandId = commandId,
		phase = phase,
		result = result,
	}
end

function CommandRouter:start()
	self.remotes.command.OnServerEvent:Connect(function(player, rawEnvelope)
		local playerId = self.playerIdResolver(player)
		local key = tostring(playerId)
		if not self.rateLimiter:allow(key) then
			self.remotes.receipt:FireClient(
				player,
				receipt(
					nil,
					"rejected",
					Result.err("RATE_LIMITED", "error.security.rate_limited", true)
				)
			)
			return
		end

		local envelopeResult = Envelope.validateCommand(rawEnvelope)
		if not envelopeResult.ok then
			self.remotes.receipt:FireClient(player, receipt(nil, "rejected", envelopeResult))
			return
		end
		local envelope = envelopeResult.value
		self.remotes.receipt:FireClient(
			player,
			receipt(envelope.commandId, "accepted", Result.ok({ status = "accepted" }))
		)

		local context = {
			player = player,
			playerId = playerId,
			role = self.roleResolver(player),
			origin = "remote",
			commandId = envelope.commandId,
			correlationId = envelope.correlationId,
		}
		local terminalResult = nil
		if self.commandGuard ~= nil then
			local guardResult = self.commandGuard(context, envelope)
			if not guardResult.ok then
				terminalResult = guardResult
			end
		end
		if terminalResult == nil then
			terminalResult = self.runtime:execute(context, envelope)
		end

		self.remotes.receipt:FireClient(
			player,
			receipt(envelope.commandId, "terminal", terminalResult)
		)
		if terminalResult.ok then
			self.projectionPublisher:publishAll()
		else
			self.diagnostics:increment("command.failed")
		end
	end)
end

return CommandRouter
