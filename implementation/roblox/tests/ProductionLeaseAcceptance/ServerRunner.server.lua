--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

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

local projectRoot = ServerStorage:WaitForChild("RVTT")
local phase = phaseValue.Value
local authorityStoreValue = projectRoot:WaitForChild("AuthorityStoreName") :: StringValue
local authorityKeyValue = projectRoot:WaitForChild("AuthorityKey") :: StringValue
local leaseStoreValue = projectRoot:WaitForChild("LeaseStoreName") :: StringValue
local ownerValue = projectRoot:WaitForChild("LeaseOwnerId") :: StringValue
local authorityStoreName = authorityStoreValue.Value
local authorityKey = authorityKeyValue.Value
local leaseStoreName = leaseStoreValue.Value
local expectedOwnerId = ownerValue.Value
local metaKey = authorityKey .. ":meta"

local passed = 0
local failed = 0
local failures: { string } = {}
local clientReport: any = nil

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

local function waitUntil(timeoutSeconds: number, predicate: () -> boolean): boolean
	local deadline = os.clock() + timeoutSeconds
	while os.clock() < deadline do
		if predicate() then
			return true
		end
		task.wait(0.1)
	end
	return predicate()
end

local function readDataStore(storeName: string, key: string): (boolean, any)
	local ok, valueOrFailure = pcall(function()
		return DataStoreService:GetDataStore(storeName):GetAsync(key)
	end)
	return ok, valueOrFailure
end

local function sameFence(left: any, right: any): boolean
	return type(left) == "table"
		and type(right) == "table"
		and left.ownerId == right.ownerId
		and left.token == right.token
		and left.fencingToken == right.fencingToken
end

if not RunService:IsStudio() then
	warn("[RVTT Production Lease] acceptance must run in Studio with API access enabled")
	return
end

if phase ~= "seed" and phase ~= "verify" then
	warn("[RVTT Production Lease] unknown phase=" .. phase)
	return
end

local reportConnection = testEvent.OnServerEvent:Connect(function(player: Player, report: any)
	if
		clientReport == nil
		and type(report) == "table"
		and report.phase == phase
		and report.userId == player.UserId
	then
		clientReport = report
	end
end)
testEvent:SetAttribute("ServerReady", true)

local startupFinished = waitUntil(45, function()
	return projectRoot:GetAttribute("ProductionLeasePersistenceReady") == true
		or projectRoot:GetAttribute("ProductionLeasePersistenceStartupCode") ~= ""
end)
expect(startupFinished, "ServerBoot reports a persistence startup result")
equal(
	projectRoot:GetAttribute("ProductionLeasePersistenceStartupCode"),
	"",
	"ServerBoot starts without a persistence error"
)
expect(
	projectRoot:GetAttribute("ProductionLeasePersistenceReady") == true,
	"ServerBoot reaches persistence ready"
)
expect(
	projectRoot:GetAttribute("ProductionLeaseLeaseActive") == true,
	"ServerBoot owns an active lease"
)
equal(
	projectRoot:GetAttribute("ProductionLeaseLeaseOwnerId"),
	expectedOwnerId,
	"ServerBoot uses the acceptance owner id"
)

local reportArrived = waitUntil(60, function()
	return clientReport ~= nil
end)
expect(reportArrived, "acceptance client reports the remote command result")
if clientReport ~= nil then
	expect(clientReport.ok == true, "acceptance client command and projection checks pass")
	expect(clientReport.membershipAfter == true, "session membership exists after the remote command")
end

local statusRevision = projectRoot:GetAttribute("ProductionLeaseAuthorityRevision")
if clientReport ~= nil then
	expect(
		type(statusRevision) == "number" and statusRevision >= clientReport.revision,
		"ServerBoot status observes the committed client revision"
	)
end

if phase == "seed" then
	equal(
		projectRoot:GetAttribute("ProductionLeaseLeaseFencingToken"),
		1,
		"clean seed acquires fencing token one"
	)
	projectRoot:SetAttribute("ProductionLeaseAcceptanceChecksPassed", failed == 0)
	projectRoot:SetAttribute("ProductionLeaseAcceptanceStaleBlocked", false)
	print(
		string.format(
			"[RVTT Production Lease Prompt] phase=seed action=close-studio checks=%s passed=%d failed=%d revision=%s fence=%s",
			if failed == 0 then "PASS" else "FAIL",
			passed,
			failed,
			tostring(statusRevision),
			tostring(projectRoot:GetAttribute("ProductionLeaseLeaseFencingToken"))
		)
	)
	for _, failure in failures do
		warn("[RVTT Production Lease Seed]", failure)
	end
	reportConnection:Disconnect()
	return
end

if clientReport ~= nil then
	expect(clientReport.membershipBefore == true, "verify projection contains the seed membership")
end

local metaOk, metaOrFailure = readDataStore(authorityStoreName, metaKey)
expect(metaOk, "verify reads the seed fence metadata")
local seedMeta = if metaOk then metaOrFailure else nil
expect(type(seedMeta) == "table", "verify finds seed fence metadata")
if type(seedMeta) == "table" then
	expect(seedMeta.checksPassed == true, "seed shutdown recorded successful pre-close checks")
	equal(seedMeta.ownerId, "acceptance:production-lease:seed", "seed metadata records the seed owner")
	equal(seedMeta.fencingToken, 1, "seed metadata records fencing token one")
end

local currentFenceToken = projectRoot:GetAttribute("ProductionLeaseLeaseFencingToken")
expect(
	type(currentFenceToken) == "number"
		and type(seedMeta) == "table"
		and currentFenceToken > seedMeta.fencingToken,
	"verify ServerBoot claims a higher fencing token"
)

local rawBeforeOk, rawBeforeOrFailure = readDataStore(authorityStoreName, authorityKey)
expect(rawBeforeOk, "verify reads the claimed authority document")
local rawBefore = if rawBeforeOk then rawBeforeOrFailure else nil
expect(type(rawBefore) == "table", "verify finds the claimed authority document")
if type(rawBefore) == "table" then
	expect(type(rawBefore.persistenceFence) == "table", "claimed document contains persistence fence metadata")
	equal(
		rawBefore.persistenceFence.ownerId,
		expectedOwnerId,
		"claimed document belongs to the verify server"
	)
	equal(
		rawBefore.persistenceFence.fencingToken,
		currentFenceToken,
		"claimed document uses the verify fencing token"
	)
end

local staleBlocked = false
if type(seedMeta) == "table" and type(rawBefore) == "table" then
	local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)
	local Version = require(ReplicatedStorage.RVTT.Shared.Core.Version)
	local Server = ServerScriptService.RVTT.Server
	local Diagnostics = require(Server.Runtime.Diagnostics)
	local MigrationRegistry = require(Server.Persistence.MigrationRegistry)
	local ProfileStore = require(Server.Persistence.ProfileStore)
	local migrations = MigrationRegistry.new(Version.SCHEMA)
	local migrationModule = projectRoot.Migrations:WaitForChild("001_InitialSchema")
	migrations:register(0, require(migrationModule))
	local profileStore = ProfileStore.new(authorityStoreName, migrations, Diagnostics.new())
	local staleCandidate = DeepCopy(rawBefore)
	staleCandidate.persistenceFence = nil
	staleCandidate.revision = math.max(99, (rawBefore.revision :: number) + 50)
	staleCandidate.authorityEpoch = seedMeta.authorityEpoch
	local staleResult = profileStore:save(authorityKey, staleCandidate, {
		ownerId = seedMeta.ownerId,
		token = seedMeta.token,
		fencingToken = seedMeta.fencingToken,
	})
	staleBlocked = not staleResult.ok and staleResult.error.code == "PERSISTENCE_FENCED"
	expect(staleBlocked, "previous seed fence cannot write revision 99 after verify claim")

	local rawAfterOk, rawAfterOrFailure = readDataStore(authorityStoreName, authorityKey)
	expect(rawAfterOk, "verify reads the authority document after the stale write attempt")
	local rawAfter = if rawAfterOk then rawAfterOrFailure else nil
	if type(rawAfter) == "table" then
		equal(rawAfter.revision, rawBefore.revision, "stale write cannot replace the claimed revision")
		expect(
			sameFence(rawAfter.persistenceFence, rawBefore.persistenceFence),
			"stale write cannot replace the claimed persistence fence"
		)
	else
		expect(false, "authority document remains present after stale write rejection")
	end
end

local leaseReadOk, leaseOrFailure = readDataStore(leaseStoreName, authorityKey)
expect(leaseReadOk, "verify reads the active lease record")
if leaseReadOk and type(leaseOrFailure) == "table" then
	equal(leaseOrFailure.ownerId, expectedOwnerId, "active lease belongs to the verify server")
	equal(
		leaseOrFailure.fencingToken,
		currentFenceToken,
		"active lease and authority fence use the same fencing token"
	)
else
	expect(false, "verify finds the active lease record")
end

projectRoot:SetAttribute("ProductionLeaseAcceptanceStaleBlocked", staleBlocked)
projectRoot:SetAttribute("ProductionLeaseAcceptanceChecksPassed", failed == 0)
print(
	string.format(
		"[RVTT Production Lease Prompt] phase=verify action=close-studio checks=%s passed=%d failed=%d revision=%s seedFence=%s verifyFence=%s staleBlocked=%s",
		if failed == 0 then "PASS" else "FAIL",
		passed,
		failed,
		tostring(statusRevision),
		tostring(if type(seedMeta) == "table" then seedMeta.fencingToken else nil),
		tostring(currentFenceToken),
		tostring(staleBlocked)
	)
)
for _, failure in failures do
	warn("[RVTT Production Lease Verify]", failure)
end
reportConnection:Disconnect()
