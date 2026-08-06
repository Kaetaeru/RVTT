--!strict

local function newSynchronousSignal(): any
	local listeners = {}
	local nextId = 0
	local signal = {}

	function signal:Connect(callback: (...any) -> ())
		nextId += 1
		local listenerId = nextId
		listeners[listenerId] = callback
		local connection = {}
		function connection:Disconnect()
			listeners[listenerId] = nil
		end
		return connection
	end

	function signal:Fire(...)
		for _, callback in listeners do
			callback(...)
		end
	end

	return signal
end

local function projection(epoch: string, revision: number, sequence: number, value: string): any
	return {
		protocolVersion = 1,
		authorityEpoch = epoch,
		revision = revision,
		projectionSequence = sequence,
		projectionType = "full",
		payload = { value = value },
	}
end

return function(harness: any)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local StarterPlayer = game:GetService("StarterPlayer")
	local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
	local clientModules = StarterPlayer.StarterPlayerScripts.RVTT.Client
	local ProjectionReplica = require(clientModules.ProjectionReplica)
	local CommandClient = require(clientModules.CommandClient)
	local FaultTransport = require(script.Parent.FaultTransport)

	local transport = FaultTransport.new()
	local replica = ProjectionReplica.new()
	local deliveryResults = {}
	local gapCount = 0
	replica.GapDetected:Connect(function()
		gapCount += 1
	end)

	local function deliver(envelope: any)
		table.insert(deliveryResults, replica:apply(envelope, false))
	end

	transport:send("epoch-a-1", projection("epoch-a", 1, 1, "one"), deliver, "deliver")
	transport:flush()
	harness:expect(deliveryResults[#deliveryResults] == true, "initial projection is delivered")
	harness:equal(replica.sequence, 1, "initial projection sequence is committed")

	transport:send("epoch-a-1-duplicate", projection("epoch-a", 1, 1, "one"), deliver, "duplicate")
	transport:flush()
	harness:expect(
		deliveryResults[#deliveryResults] == false
			and deliveryResults[#deliveryResults - 1] == false,
		"duplicate projections are ignored"
	)
	harness:equal(gapCount, 0, "duplicate projection does not create a false gap")

	transport:send("epoch-a-2", projection("epoch-a", 2, 2, "two"), deliver, "drop")
	transport:send("epoch-a-3", projection("epoch-a", 3, 3, "three"), deliver, "deliver")
	transport:flush()
	harness:expect(
		deliveryResults[#deliveryResults] == false,
		"projection after a dropped packet is rejected"
	)
	harness:equal(gapCount, 1, "dropped projection creates one gap signal")
	harness:equal(replica.sequence, 1, "gap rejection preserves the last contiguous projection")

	local resynced = replica:apply(projection("epoch-a", 3, 3, "three"), true)
	harness:expect(resynced, "forced full resync accepts the authoritative snapshot")
	harness:equal(replica.sequence, 3, "full resync advances the projection sequence")

	transport:send("epoch-a-4", projection("epoch-a", 4, 4, "four"), deliver, "hold")
	transport:send("epoch-a-5", projection("epoch-a", 5, 5, "five"), deliver, "deliver")
	transport:flush()
	harness:expect(
		deliveryResults[#deliveryResults] == false,
		"reordered future projection is rejected"
	)
	harness:equal(gapCount, 2, "reordered future projection creates a gap signal")
	harness:equal(
		transport:release("epoch-a-4", true),
		1,
		"held projection is released deterministically"
	)
	transport:flush()
	harness:expect(
		deliveryResults[#deliveryResults] == true,
		"released missing projection is accepted"
	)
	transport:send("epoch-a-5-retry", projection("epoch-a", 5, 5, "five"), deliver, "deliver")
	transport:flush()
	harness:expect(
		deliveryResults[#deliveryResults] == true,
		"future projection succeeds after gap recovery"
	)
	harness:equal(replica.sequence, 5, "reordered stream recovers to the latest sequence")

	transport:send("epoch-b-1", projection("epoch-b", 6, 1, "new epoch"), deliver, "deliver")
	transport:flush()
	harness:expect(deliveryResults[#deliveryResults] == true, "new authority epoch is accepted")
	harness:equal(replica.epoch, "epoch-b", "replica switches to the new authority epoch")

	transport:send(
		"epoch-a-delayed",
		projection("epoch-a", 7, 6, "stale epoch"),
		deliver,
		"deliver"
	)
	transport:flush()
	harness:expect(deliveryResults[#deliveryResults] == false, "delayed previous epoch is rejected")
	harness:equal(replica.epoch, "epoch-b", "delayed epoch cannot roll back the replica")
	harness:equal(
		replica.payload.value,
		"new epoch",
		"delayed epoch cannot replace current payload"
	)

	local now = 0
	local receiptSignal = newSynchronousSignal()
	local sentEnvelopes = {}
	local remotes = {
		command = {
			FireServer = function(_self: any, envelope: any)
				table.insert(sentEnvelopes, envelope)
			end,
		},
		receipt = { OnClientEvent = receiptSignal },
	}
	local commandReplica = { epoch = "command-epoch", revision = 12 }
	local client = CommandClient.new(remotes, commandReplica, function()
		return now
	end)
	local receipts = {}
	client:start(function(message: any)
		table.insert(receipts, message)
	end, false)

	local commandId = client:submit("session.ready", { ready = true })
	harness:equal(#sentEnvelopes, 1, "command is sent once initially")
	harness:expect(
		client.pending[commandId] ~= nil,
		"command remains pending without a terminal receipt"
	)

	now += CommandClient.RETRY_INTERVAL_SECONDS
	client:tick(now)
	harness:equal(#sentEnvelopes, 2, "lost terminal receipt triggers a retry")
	harness:equal(
		sentEnvelopes[2].commandId,
		commandId,
		"retry reuses the original command identity"
	)
	harness:equal(receipts[#receipts].phase, "retrying", "retry emits a structured receipt phase")

	now += CommandClient.RETRY_INTERVAL_SECONDS
	client:tick(now)
	harness:equal(#sentEnvelopes, 3, "command retries up to the bounded attempt count")
	now += CommandClient.RETRY_INTERVAL_SECONDS
	client:tick(now)
	harness:equal(#sentEnvelopes, 3, "command does not exceed the bounded attempt count")

	receiptSignal:Fire({
		commandId = commandId,
		phase = "terminal",
		result = Result.ok({ status = "committed" }),
	})
	harness:expect(client.pending[commandId] == nil, "terminal receipt clears the retried command")

	local timeoutCommandId = client:submit("session.ready", { ready = false })
	now += CommandClient.COMMAND_TIMEOUT_SECONDS
	client:tick(now)
	harness:expect(
		client.pending[timeoutCommandId] == nil,
		"timed out command is removed from pending state"
	)
	local timeoutReceipt = receipts[#receipts]
	harness:equal(timeoutReceipt.phase, "terminal", "timeout produces a terminal client receipt")
	harness:expect(not timeoutReceipt.result.ok, "timeout terminal receipt is a failure")
	if not timeoutReceipt.result.ok then
		harness:equal(
			timeoutReceipt.result.error.code,
			"CLIENT_TIMEOUT",
			"timeout failure code is explicit"
		)
		harness:expect(
			timeoutReceipt.result.error.retryable,
			"command timeout remains retryable to the user flow"
		)
	end
	client:stop()

	local metrics = transport:metricsSnapshot()
	print(
		string.format(
			"[RVTT Fault Host] kind=network sent=%d delivered=%d dropped=%d duplicated=%d held=%d released=%d gaps=%d retries=%d",
			metrics.sent,
			metrics.delivered,
			metrics.dropped,
			metrics.duplicated,
			metrics.held,
			metrics.released,
			gapCount,
			#sentEnvelopes - 2
		)
	)
end
