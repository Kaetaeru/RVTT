--!strict

return function(harness: any)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
	local Version = require(ReplicatedStorage.RVTT.Shared.Core.Version)
	local CommandRouter = require(Server.Networking.CommandRouter)

	local commandEvent: any = { callback = nil }
	function commandEvent:Connect(callback: any)
		self.callback = callback
	end

	local receiptRemote: any = { calls = {} }
	function receiptRemote:FireClient(player: any, value: any)
		table.insert(self.calls, { player = player, value = value })
	end

	local remotes = {
		command = commandEvent,
		receipt = receiptRemote,
	}
	local runtime: any = { executeCalls = 0 }
	function runtime:execute(_context: any, envelope: any): any
		self.executeCalls += 1
		return Result.ok({ commandId = envelope.commandId })
	end
	local limiter = {}
	function limiter:allow(_key: string): boolean
		return true
	end
	local publisher: any = { publishCalls = 0 }
	function publisher:publishAll()
		self.publishCalls += 1
	end
	local diagnostics: any = { counters = {} }
	function diagnostics:increment(key: string)
		self.counters[key] = (self.counters[key] or 0) + 1
	end

	local guardResult: any = Result.err("LEASE_LOST", "error.persistence.lease_lost", false)
	local guardCalls = 0
	local router = CommandRouter.new(
		runtime,
		remotes,
		limiter,
		function(_player: any): string
			return "player"
		end,
		publisher,
		diagnostics,
		function(_player: any): number
			return 42
		end,
		function(_context: any, _envelope: any): any
			guardCalls += 1
			return guardResult
		end
	)
	router:start()

	local player = {} :: any
	local function envelope(commandId: string): any
		return {
			protocolVersion = Version.PROTOCOL,
			commandId = commandId,
			commandType = "test.command",
			correlationId = commandId,
			authorityEpoch = "epoch:test",
			expectedRevision = 0,
			payload = {},
		}
	end

	commandEvent.callback(player, envelope("command:blocked"))
	harness:equal(guardCalls, 1, "valid command invokes the lease guard")
	harness:equal(runtime.executeCalls, 0, "failed guard prevents authority execution")
	harness:equal(publisher.publishCalls, 0, "failed guard prevents projection publication")
	harness:equal(
		#receiptRemote.calls,
		2,
		"blocked command still receives accepted and terminal receipts"
	)
	harness:equal(receiptRemote.calls[2].value.phase, "terminal", "guard failure is terminal")
	harness:equal(
		receiptRemote.calls[2].value.result.error.code,
		"LEASE_LOST",
		"terminal receipt preserves the lease failure code"
	)

	guardResult = Result.ok(true)
	commandEvent.callback(player, envelope("command:allowed"))
	harness:equal(guardCalls, 2, "second valid command invokes the guard again")
	harness:equal(runtime.executeCalls, 1, "successful guard permits authority execution")
	harness:equal(publisher.publishCalls, 1, "successful command publishes projections")
end
