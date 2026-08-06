--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local testMode = ReplicatedStorage:FindFirstChild("RVTT_TestMode")
if testMode == nil or not testMode:IsA("StringValue") or testMode.Value ~= "real-transport" then
	return
end

local player = Players.LocalPlayer
local identityDeadline = os.clock() + 30
while os.clock() < identityDeadline and player:GetAttribute("RVTT_TransportActive") == nil do
	task.wait(0.05)
end
if player:GetAttribute("RVTT_TransportActive") ~= true then
	return
end

local role = player:GetAttribute("RVTT_Role")
local testUserId = player:GetAttribute("RVTT_TestUserId")
local reconnectGeneration = player:GetAttribute("RVTT_ReconnectGeneration")
assert(type(role) == "string", "real transport role was not assigned")
assert(type(testUserId) == "number", "real transport user id was not assigned")
assert(
	type(reconnectGeneration) == "number",
	"real transport reconnect generation was not assigned"
)

local coordination = ReplicatedStorage:WaitForChild("RVTT_RealTransport")
local control = coordination:WaitForChild("Control") :: RemoteEvent
local reportRemote = coordination:WaitForChild("Report") :: RemoteEvent

local Names = require(ReplicatedStorage.RVTT.Shared.Protocol.RemoteNames)
local Version = require(ReplicatedStorage.RVTT.Shared.Core.Version)
local remoteFolder = ReplicatedStorage:WaitForChild(Names.FOLDER)
local commandRemote = remoteFolder:WaitForChild(Names.COMMAND) :: RemoteEvent
local receiptRemote = remoteFolder:WaitForChild(Names.RECEIPT) :: RemoteEvent
local syncRemote = remoteFolder:WaitForChild(Names.SYNC) :: RemoteFunction

local terminalByCommandId: { [string]: any } = {}
receiptRemote.OnClientEvent:Connect(function(message)
	if type(message) ~= "table" or message.phase ~= "terminal" then
		return
	end
	local commandId = message.commandId
	if type(commandId) == "string" then
		terminalByCommandId[commandId] = message.result
	end
end)

local function report(message: any)
	message.role = role
	message.testUserId = testUserId
	message.reconnectGeneration = reconnectGeneration
	reportRemote:FireServer(message)
end

local function failure(code: string): any
	return {
		ok = false,
		error = {
			code = code,
			messageKey = "error.test.real_transport",
			retryable = false,
		},
	}
end

local function syncProjection(): any
	for _ = 1, 30 do
		local ok, projection = pcall(function()
			return syncRemote:InvokeServer()
		end)
		if ok and type(projection) == "table" then
			return projection
		end
		task.wait(0.1)
	end
	return nil
end

local function waitForTerminal(commandId: string): any
	local deadline = os.clock() + 12
	while os.clock() < deadline do
		local terminal = terminalByCommandId[commandId]
		if terminal ~= nil then
			terminalByCommandId[commandId] = nil
			return terminal
		end
		task.wait(0.02)
	end
	return nil
end

local function sendUsingProjection(commandType: string, payload: any, projection: any): any
	if type(projection) ~= "table" then
		return failure("SYNC_FAILED")
	end
	local commandId = HttpService:GenerateGUID(false)
	commandRemote:FireServer({
		protocolVersion = Version.PROTOCOL,
		commandId = commandId,
		commandType = commandType,
		correlationId = commandId,
		authorityEpoch = projection.authorityEpoch,
		expectedRevision = projection.revision,
		payload = payload,
	})
	return waitForTerminal(commandId) or failure("RECEIPT_TIMEOUT")
end

local function sendWithRetry(commandType: string, payload: any): (any, number)
	local staleRetries = 0
	for _ = 1, 8 do
		local projection = syncProjection()
		local result = sendUsingProjection(commandType, payload, projection)
		if result.ok then
			return result, staleRetries
		end
		local code = if result.error ~= nil then result.error.code else nil
		if code ~= "STALE_REVISION" and code ~= "STALE_EPOCH" then
			return result, staleRetries
		end
		staleRetries += 1
	end
	return failure("STALE_RETRY_EXHAUSTED"), staleRetries
end

local function membershipCount(session: any): number
	if type(session) ~= "table" or type(session.memberships) ~= "table" then
		return 0
	end
	local count = 0
	for _ in session.memberships do
		count += 1
	end
	return count
end

local initialProjection = syncProjection()
report({
	phase = "ready",
	revision = if initialProjection ~= nil then initialProjection.revision else -1,
	authorityEpoch = if initialProjection ~= nil then initialProjection.authorityEpoch else nil,
})

control.OnClientEvent:Connect(function(message)
	if type(message) ~= "table" or type(message.phase) ~= "string" then
		return
	end
	task.spawn(function()
		if message.phase == "join" then
			local result, staleRetries = sendWithRetry("session.join", {})
			report({
				phase = "join",
				ok = result.ok,
				errorCode = if result.ok then nil else result.error.code,
				staleRetries = staleRetries,
			})
			return
		end

		if message.phase == "prepare_disconnect" then
			report({ phase = "disconnect_ready" })
			print("[RVTT Real Transport Client] close this player client window now")
			return
		end

		if message.phase == "validate_reconnect" then
			local joinResult, staleRetries = sendWithRetry("session.join", {})
			local first = syncProjection()
			local second = syncProjection()
			local domains = if second ~= nil and type(second.payload) == "table"
				then second.payload.domains
				else nil
			local session = if type(domains) == "table" then domains.session else nil
			local connection = if type(session) == "table"
					and type(session.connections) == "table"
				then session.connections[tostring(testUserId)]
				else nil
			report({
				phase = "reconnect",
				ok = joinResult.ok,
				errorCode = if joinResult.ok then nil else joinResult.error.code,
				staleRetries = staleRetries,
				revision = if second ~= nil then second.revision else -1,
				authorityEpoch = if second ~= nil then second.authorityEpoch else nil,
				sequenceIncreasing = first ~= nil
					and second ~= nil
					and second.projectionSequence > first.projectionSequence,
				membershipCount = membershipCount(session),
				connection = connection,
			})
		end
	end)
end)
