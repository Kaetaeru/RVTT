--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local testMode = ReplicatedStorage:FindFirstChild("RVTT_TestMode")
if testMode == nil or not testMode:IsA("StringValue") or testMode.Value ~= "multi-client" then
	return
end

local player = Players.LocalPlayer
local identityDeadline = os.clock() + 20
while os.clock() < identityDeadline and player:GetAttribute("RVTT_MultiClientActive") == nil do
	task.wait(0.05)
end
if player:GetAttribute("RVTT_MultiClientActive") ~= true then
	return
end

local role = player:GetAttribute("RVTT_Role")
local testUserId = player:GetAttribute("RVTT_TestUserId")
assert(type(role) == "string", "multi-client role was not assigned")
assert(type(testUserId) == "number", "multi-client test user id was not assigned")

local coordination = ReplicatedStorage:WaitForChild("RVTT_MultiClient")
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
	reportRemote:FireServer(message)
end

local function failure(code: string): any
	return {
		ok = false,
		error = {
			code = code,
			messageKey = "error.test.multi_client",
			retryable = false,
		},
	}
end

local function syncProjection(): any
	for _ = 1, 20 do
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
	local deadline = os.clock() + 10
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

local function sendWithRetry(
	commandType: string,
	payload: any,
	firstProjection: any?
): (any, number)
	local projection = firstProjection
	local staleRetries = 0
	for _ = 1, 8 do
		if projection == nil then
			projection = syncProjection()
		end
		local result = sendUsingProjection(commandType, payload, projection)
		if result.ok then
			return result, staleRetries
		end
		local errorCode = if result.error ~= nil then result.error.code else nil
		if errorCode ~= "STALE_REVISION" and errorCode ~= "STALE_EPOCH" then
			return result, staleRetries
		end
		staleRetries += 1
		projection = syncProjection()
	end
	return failure("STALE_RETRY_EXHAUSTED"), staleRetries
end

local initialProjection = syncProjection()

control.OnClientEvent:Connect(function(message)
	if type(message) ~= "table" or type(message.phase) ~= "string" then
		return
	end
	task.spawn(function()
		if message.phase == "concurrent_join" then
			local result, staleRetries = sendWithRetry("session.join", {}, initialProjection)
			report({
				phase = "join",
				ok = result.ok,
				errorCode = if result.ok then nil else result.error.code,
				staleRetries = staleRetries,
			})
			return
		end

		if message.phase == "unauthorized" then
			if role == "dm" then
				report({ phase = "unauthorized", skipped = true })
				return
			end
			local result, staleRetries = sendWithRetry("dm.quick_action", {
				actionId = "forbidden:" .. role,
			})
			report({
				phase = "unauthorized",
				ok = result.ok,
				errorCode = if result.ok then nil else result.error.code,
				staleRetries = staleRetries,
			})
			return
		end

		if message.phase == "dm_action" then
			if role ~= "dm" then
				report({ phase = "dm_action", skipped = true })
				return
			end
			local result, staleRetries = sendWithRetry("dm.quick_action", {
				actionId = "multi-client-authorized",
			})
			report({
				phase = "dm_action",
				ok = result.ok,
				errorCode = if result.ok then nil else result.error.code,
				staleRetries = staleRetries,
			})
			return
		end

		if message.phase == "create_draft" then
			if role == "observer" then
				report({ phase = "create_draft", skipped = true })
				return
			end
			local result, staleRetries = sendWithRetry("character.create_draft", {
				name = "MultiClient " .. role,
			})
			local draftId = nil
			if
				result.ok
				and type(result.value) == "table"
				and type(result.value.outcome) == "table"
			then
				draftId = result.value.outcome.id
			end
			report({
				phase = "create_draft",
				ok = result.ok,
				errorCode = if result.ok then nil else result.error.code,
				staleRetries = staleRetries,
				draftId = draftId,
			})
			return
		end

		if message.phase == "inspect" then
			local projection = syncProjection()
			local domains = if projection ~= nil and type(projection.payload) == "table"
				then projection.payload.domains
				else nil
			local character = if type(domains) == "table" then domains.character else nil
			local drafts = if type(character) == "table"
					and type(character.drafts) == "table"
				then character.drafts
				else {}
			local workspace = if type(domains) == "table"
					and type(domains.dm_workspace) == "table"
				then domains.dm_workspace
				else {}
			local dmDraft = if type(message.dmDraftId) == "string"
				then drafts[message.dmDraftId]
				else nil
			local playerDraft = if type(message.playerDraftId) == "string"
				then drafts[message.playerDraftId]
				else nil
			report({
				phase = "inspect",
				projectionOk = projection ~= nil,
				hasDmDraft = dmDraft ~= nil,
				hasPlayerDraft = playerDraft ~= nil,
				dmPrivate = type(dmDraft) == "table" and dmDraft.abilities ~= nil,
				playerPrivate = type(playerDraft) == "table" and playerDraft.abilities ~= nil,
				workspaceVisible = next(workspace) ~= nil,
			})
			return
		end

		if message.phase == "resync" then
			local first = syncProjection()
			local second = syncProjection()
			report({
				phase = "resync",
				sequenceIncreasing = first ~= nil
					and second ~= nil
					and second.projectionSequence > first.projectionSequence,
				revisionStable = first ~= nil
					and second ~= nil
					and second.revision == first.revision,
				epochStable = first ~= nil
					and second ~= nil
					and second.authorityEpoch == first.authorityEpoch,
			})
		end
	end)
end)

report({
	phase = "ready",
	revision = if initialProjection ~= nil then initialProjection.revision else -1,
	projectionSequence = if initialProjection ~= nil
		then initialProjection.projectionSequence
		else -1,
})
