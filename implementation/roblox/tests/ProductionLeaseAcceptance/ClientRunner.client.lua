--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local phaseValue = ReplicatedStorage:FindFirstChild("RVTT_ProductionLeasePhase")
local testEvent = ReplicatedStorage:FindFirstChild("RVTT_ProductionLeaseTestEvent")
if
	phaseValue == nil
	or not phaseValue:IsA("StringValue")
	or testEvent == nil
	or not testEvent:IsA("RemoteEvent")
then
	return
end

local RemoteNames = require(ReplicatedStorage.RVTT.Shared.Protocol.RemoteNames)
local Version = require(ReplicatedStorage.RVTT.Shared.Core.Version)
local player = Players.LocalPlayer
local phase = phaseValue.Value

local remoteFolder = ReplicatedStorage:WaitForChild(RemoteNames.FOLDER, 30)
assert(remoteFolder ~= nil and remoteFolder:IsA("Folder"), "RVTT remotes were not published")
local commandRemote = remoteFolder:WaitForChild(RemoteNames.COMMAND, 30) :: RemoteEvent
local receiptRemote = remoteFolder:WaitForChild(RemoteNames.RECEIPT, 30) :: RemoteEvent
local syncRemote = remoteFolder:WaitForChild(RemoteNames.SYNC, 30) :: RemoteFunction

local function waitForServerReady(timeoutSeconds: number): boolean
	local deadline = os.clock() + timeoutSeconds
	while os.clock() < deadline do
		if testEvent:GetAttribute("ServerReady") == true then
			return true
		end
		task.wait(0.1)
	end
	return false
end

local function requestProjection(): any
	local deadline = os.clock() + 20
	local lastFailure = "sync timeout"
	while os.clock() < deadline do
		local ok, valueOrFailure = pcall(function()
			return syncRemote:InvokeServer()
		end)
		if ok and type(valueOrFailure) == "table" then
			return valueOrFailure
		end
		lastFailure = tostring(valueOrFailure)
		task.wait(0.25)
	end
	error("projection sync failed: " .. lastFailure)
end

local function submitJoin(): any
	local lastResult: any = nil
	for attempt = 1, 3 do
		local projection = requestProjection()
		local commandId = HttpService:GenerateGUID(false)
		local terminal: any = nil
		local connection = receiptRemote.OnClientEvent:Connect(function(message: any)
			if
				type(message) == "table"
				and message.commandId == commandId
				and message.phase == "terminal"
			then
				terminal = message
			end
		end)
		commandRemote:FireServer({
			protocolVersion = Version.PROTOCOL,
			commandId = commandId,
			commandType = "session.join",
			correlationId = commandId,
			authorityEpoch = projection.authorityEpoch,
			expectedRevision = projection.revision,
			payload = {},
		})

		local deadline = os.clock() + 10
		while terminal == nil and os.clock() < deadline do
			task.wait(0.05)
		end
		connection:Disconnect()
		if terminal == nil then
			lastResult = {
				ok = false,
				error = { code = "CLIENT_TIMEOUT" },
			}
		elseif terminal.result.ok then
			return terminal.result
		else
			lastResult = terminal.result
			if terminal.result.error.code ~= "STALE_REVISION" then
				break
			end
		end
		task.wait(0.1 * attempt)
	end
	return lastResult
end

local serverReady = waitForServerReady(30)
local beforeProjection: any = nil
local afterProjection: any = nil
local commandResult: any = nil
local ok, failure = xpcall(function()
	beforeProjection = requestProjection()
	commandResult = submitJoin()
	afterProjection = requestProjection()
end, debug.traceback)

local userKey = tostring(player.UserId)
local membershipBefore = ok
	and type(beforeProjection.payload) == "table"
	and type(beforeProjection.payload.domains) == "table"
	and type(beforeProjection.payload.domains.session) == "table"
	and type(beforeProjection.payload.domains.session.memberships[userKey]) == "table"
local membershipAfter = ok
	and type(afterProjection.payload) == "table"
	and type(afterProjection.payload.domains) == "table"
	and type(afterProjection.payload.domains.session) == "table"
	and type(afterProjection.payload.domains.session.memberships[userKey]) == "table"
local commandOk = ok and commandResult ~= nil and commandResult.ok == true
local resultOk = serverReady
	and commandOk
	and membershipAfter
	and (phase ~= "verify" or membershipBefore)
local errorCode = ""
if not ok then
	errorCode = tostring(failure)
elseif not serverReady then
	errorCode = "SERVER_NOT_READY"
elseif commandResult ~= nil and not commandResult.ok then
	errorCode = tostring(commandResult.error.code)
elseif not membershipAfter then
	errorCode = "MEMBERSHIP_MISSING_AFTER"
elseif phase == "verify" and not membershipBefore then
	errorCode = "RESTORED_MEMBERSHIP_MISSING"
end

local report = {
	phase = phase,
	ok = resultOk,
	userId = player.UserId,
	membershipBefore = membershipBefore,
	membershipAfter = membershipAfter,
	revision = if afterProjection ~= nil then afterProjection.revision else -1,
	authorityEpoch = if afterProjection ~= nil then afterProjection.authorityEpoch else "missing",
	errorCode = errorCode,
}
testEvent:FireServer(report)
print(
	string.format(
		"[RVTT Production Lease Client] phase=%s result=%s userId=%d membershipBefore=%s membershipAfter=%s revision=%s error=%s",
		phase,
		if resultOk then "PASS" else "FAIL",
		player.UserId,
		tostring(membershipBefore),
		tostring(membershipAfter),
		tostring(report.revision),
		errorCode
	)
)
