--!strict

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local testMode = ReplicatedStorage:FindFirstChild("RVTT_TestMode")
local roleValue = ReplicatedStorage:FindFirstChild("RVTT_LeaseRole")
if
	testMode == nil
	or not testMode:IsA("StringValue")
	or testMode.Value ~= "lease-acceptance"
	or roleValue == nil
	or not roleValue:IsA("StringValue")
then
	return
end

local role = roleValue.Value
if role ~= "holder" and role ~= "contender" then
	return
end

local Server = ServerScriptService.RVTT.Server
local Diagnostics = require(Server.Runtime.Diagnostics)
local LeaseCoordinator = require(Server.Persistence.LeaseCoordinator)
local LeaseStore = require(Server.Persistence.LeaseStore)

local LEASE_STORE_NAME = "RVTT_Lease_Integration_v1"
local COORD_STORE_NAME = "RVTT_Lease_Coordination_v1"
local LEASE_KEY = "grand:cross-server-lease"
local COORD_KEY = "grand:cross-server-lease"
local LEASE_TTL_SECONDS = 12
local WAIT_TIMEOUT_SECONDS = 90
local leaseRawStore = DataStoreService:GetDataStore(LEASE_STORE_NAME)
local coordinationStore = DataStoreService:GetDataStore(COORD_STORE_NAME)
local diagnostics = Diagnostics.new()
local leaseStore = LeaseStore.new(LEASE_STORE_NAME, diagnostics)
local ownerId = role
	.. ":"
	.. (if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false))
local coordinator =
	LeaseCoordinator.new(leaseStore, LEASE_KEY, ownerId, LEASE_TTL_SECONDS, diagnostics)
local startedAt = os.time()

local passed = 0
local failed = 0
local failures: { string } = {}

local function expect(condition: boolean, message: string)
	if condition then
		passed += 1
	else
		failed += 1
		table.insert(failures, message)
	end
end

local function equal(actual: any, expected: any, message: string)
	expect(
		actual == expected,
		message .. " expected=" .. tostring(expected) .. " actual=" .. tostring(actual)
	)
end

local function readCoord(): any
	local ok, valueOrFailure = pcall(function()
		return coordinationStore:UpdateAsync(COORD_KEY, function(current: any): any
			return current
		end)
	end)
	if not ok then
		warn("[RVTT Lease Pair] coordination read failed", valueOrFailure)
		return nil
	end
	return valueOrFailure
end

local function writeCoord(value: any): boolean
	local ok, failure = pcall(function()
		coordinationStore:SetAsync(COORD_KEY, value)
	end)
	if not ok then
		warn("[RVTT Lease Pair] coordination write failed", failure)
	end
	return ok
end

local function waitForCoord(predicate: (any) -> boolean): any
	local deadline = os.clock() + WAIT_TIMEOUT_SECONDS
	while os.clock() < deadline do
		local value = readCoord()
		if value ~= nil and predicate(value) then
			return value
		end
		task.wait(1)
	end
	return nil
end

local function finish(label: string, details: string)
	print(
		string.format(
			"[RVTT Lease %s] result=%s passed=%d failed=%d %s",
			label,
			if failed == 0 then "PASS" else "FAIL",
			passed,
			failed,
			details
		)
	)
	for _, failure in failures do
		warn("[RVTT Lease " .. label .. "]", failure)
	end
	assert(failed == 0, "RVTT cross-server lease acceptance failed")
end

if role == "holder" then
	local cleanupLease = pcall(function()
		leaseRawStore:RemoveAsync(LEASE_KEY)
	end)
	local cleanupCoord = pcall(function()
		coordinationStore:RemoveAsync(COORD_KEY)
	end)
	expect(cleanupLease, "holder clears the previous lease key")
	expect(cleanupCoord, "holder clears the previous coordination key")

	local runId = HttpService:GenerateGUID(false)
	local acquired = coordinator:acquire()
	expect(acquired.ok, "holder acquires the initial lease")
	if not acquired.ok then
		finish("Holder", "runId=" .. runId)
		return
	end
	local holderFence = coordinator:fencingToken() :: number
	local holderExpiry = coordinator:expiresAt() :: number
	expect(
		writeCoord({
			runId = runId,
			phase = "holder-ready",
			createdAt = os.time(),
			holderFence = holderFence,
			holderExpiresAt = holderExpiry,
		}),
		"holder publishes the initial lease checkpoint"
	)
	print("[RVTT Lease Pair Prompt] role=holder action=start-contender runId=" .. runId)

	local firstBlocked = waitForCoord(function(value: any): boolean
		return value.runId == runId and value.phase == "contender-blocked"
	end)
	expect(firstBlocked ~= nil, "contender observes the active holder lease")

	local renewed = coordinator:renew()
	expect(renewed.ok, "holder renews the lease while the contender is blocked")
	local renewedExpiry = coordinator:expiresAt() :: number
	equal(coordinator:fencingToken(), holderFence, "holder renewal preserves fencing token")
	expect(
		writeCoord({
			runId = runId,
			phase = "holder-renewed",
			createdAt = os.time(),
			holderFence = holderFence,
			holderExpiresAt = renewedExpiry,
		}),
		"holder publishes the renewed lease checkpoint"
	)

	local secondBlocked = waitForCoord(function(value: any): boolean
		return value.runId == runId and value.phase == "contender-blocked-renewed"
	end)
	expect(secondBlocked ~= nil, "contender remains blocked after holder renewal")
	expect(
		writeCoord({
			runId = runId,
			phase = "holder-expiring",
			createdAt = os.time(),
			holderFence = holderFence,
			holderExpiresAt = renewedExpiry,
		}),
		"holder publishes the intentional expiry checkpoint"
	)

	local takeover = waitForCoord(function(value: any): boolean
		return value.runId == runId and value.phase == "contender-acquired"
	end)
	expect(takeover ~= nil, "contender acquires after holder renewal expires")
	local takeoverFence = if takeover ~= nil then takeover.contenderFence else nil
	expect(
		type(takeoverFence) == "number" and takeoverFence > holderFence,
		"contender takeover advances the fencing token"
	)

	local staleVerify = coordinator:verify()
	expect(not staleVerify.ok, "expired holder cannot verify after takeover")
	if not staleVerify.ok then
		expect(
			staleVerify.error.code == "LEASE_EXPIRED" or staleVerify.error.code == "LEASE_LOST",
			"stale holder receives an explicit lease terminal code"
		)
	end
	local staleRelease = coordinator:release()
	expect(not staleRelease.ok, "stale holder cannot release the contender lease")

	expect(
		writeCoord({
			runId = runId,
			phase = "holder-complete",
			createdAt = os.time(),
			holderFence = holderFence,
			contenderFence = takeoverFence,
		}),
		"holder publishes completion for contender cleanup"
	)
	finish(
		"Holder",
		string.format(
			"runId=%s holderFence=%d contenderFence=%s renewals=1 takeovers=1",
			runId,
			holderFence,
			tostring(takeoverFence)
		)
	)
	return
end

local initial = waitForCoord(function(value: any): boolean
	return value.phase == "holder-ready"
		and type(value.runId) == "string"
		and type(value.createdAt) == "number"
		and value.createdAt >= startedAt - 15
end)
expect(initial ~= nil, "contender finds the current holder run")
if initial == nil then
	finish("Contender", "runId=missing")
	return
end
local runId = initial.runId
local holderFence = initial.holderFence
local firstAttempt = coordinator:acquire()
expect(not firstAttempt.ok, "contender is rejected while holder lease is active")
if not firstAttempt.ok then
	equal(firstAttempt.error.code, "LEASE_HELD", "first contention returns LEASE_HELD")
end
expect(
	writeCoord({
		runId = runId,
		phase = "contender-blocked",
		createdAt = os.time(),
		holderFence = holderFence,
	}),
	"contender publishes the first blocked checkpoint"
)

local renewed = waitForCoord(function(value: any): boolean
	return value.runId == runId and value.phase == "holder-renewed"
end)
expect(renewed ~= nil, "contender observes holder renewal")
if renewed == nil then
	finish("Contender", "runId=" .. tostring(runId))
	return
end
local renewedAttempt = coordinator:acquire()
expect(not renewedAttempt.ok, "contender remains rejected after holder renewal")
if not renewedAttempt.ok then
	equal(renewedAttempt.error.code, "LEASE_HELD", "renewed contention returns LEASE_HELD")
end
expect(
	writeCoord({
		runId = runId,
		phase = "contender-blocked-renewed",
		createdAt = os.time(),
		holderFence = holderFence,
	}),
	"contender publishes the renewed blocked checkpoint"
)

local expiring = waitForCoord(function(value: any): boolean
	return value.runId == runId and value.phase == "holder-expiring"
end)
expect(expiring ~= nil, "contender observes intentional holder expiry")
if expiring == nil then
	finish("Contender", "runId=" .. tostring(runId))
	return
end
local expiresAt = expiring.holderExpiresAt
expect(type(expiresAt) == "number", "holder expiry checkpoint contains a timestamp")
while type(expiresAt) == "number" and os.time() <= expiresAt do
	task.wait(1)
end

local takeover = coordinator:acquire()
expect(takeover.ok, "contender acquires after holder expiry")
if not takeover.ok then
	finish("Contender", "runId=" .. tostring(runId))
	return
end
local contenderFence = coordinator:fencingToken() :: number
expect(
	type(holderFence) == "number" and contenderFence > holderFence,
	"takeover fencing token is greater than holder fencing token"
)
local verified = coordinator:verify()
expect(verified.ok, "contender verifies the authoritative takeover lease")
expect(
	writeCoord({
		runId = runId,
		phase = "contender-acquired",
		createdAt = os.time(),
		holderFence = holderFence,
		contenderFence = contenderFence,
	}),
	"contender publishes the takeover checkpoint"
)

local holderComplete = waitForCoord(function(value: any): boolean
	return value.runId == runId and value.phase == "holder-complete"
end)
expect(holderComplete ~= nil, "contender observes holder stale-owner checks")
local released = coordinator:release()
expect(released.ok, "contender releases the authoritative lease")
local cleanupLease = pcall(function()
	leaseRawStore:RemoveAsync(LEASE_KEY)
end)
local cleanupCoord = pcall(function()
	coordinationStore:RemoveAsync(COORD_KEY)
end)
expect(cleanupLease, "contender removes the lease integration key")
expect(cleanupCoord, "contender removes the coordination key")
finish(
	"Contender",
	string.format(
		"runId=%s holderFence=%s contenderFence=%d blocked=2 takeovers=1",
		tostring(runId),
		tostring(holderFence),
		contenderFence
	)
)
