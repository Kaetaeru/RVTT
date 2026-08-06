--!strict

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

if
	ReplicatedStorage:FindFirstChild("RVTT_TestMode") ~= nil
	or ServerScriptService:FindFirstChild("RVTTTests") ~= nil
then
	return
end

Players.CharacterAutoLoads = false

local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local Version = require(ReplicatedStorage.RVTT.Shared.Core.Version)
local Server = script.Parent.Server
local CommandRegistry = require(Server.Runtime.CommandRegistry)
local Diagnostics = require(Server.Runtime.Diagnostics)
local EventOutbox = require(Server.Runtime.EventOutbox)
local TransactionCoordinator = require(Server.Runtime.TransactionCoordinator)
local AuthorityRuntime = require(Server.Runtime.AuthorityRuntime)
local LeaseCoordinator = require(Server.Persistence.LeaseCoordinator)
local LeaseOwnership = require(Server.Persistence.LeaseOwnership)
local LeaseProtectedStore = require(Server.Persistence.LeaseProtectedStore)
local LeaseStore = require(Server.Persistence.LeaseStore)
local MigrationRegistry = require(Server.Persistence.MigrationRegistry)
local PersistenceCoordinator = require(Server.Persistence.PersistenceCoordinator)
local ProfileStore = require(Server.Persistence.ProfileStore)
local SnapshotJournal = require(Server.Persistence.SnapshotJournal)
local RemoteBootstrap = require(Server.Networking.RemoteBootstrap)
local CommandRouter = require(Server.Networking.CommandRouter)
local ProjectionPublisher = require(Server.Networking.ProjectionPublisher)
local ProjectionBuilder = require(Server.Projection.ProjectionBuilder)
local RateLimiter = require(Server.Security.RateLimiter)
local ServiceGraph = require(Server.Bootstrap.ServiceGraph)

local DEFAULT_AUTHORITY_STORE_NAME = "RVTT_Authority_v1"
local DEFAULT_AUTHORITY_KEY = "campaign:default"
local DEFAULT_LEASE_STORE_NAME = "RVTT_AuthorityLease_v1"
local DEFAULT_LEASE_TTL_SECONDS = 30
local DEFAULT_LEASE_RENEW_INTERVAL_SECONDS = 10
local DEFAULT_LEASE_RETRY_INTERVAL_SECONDS = 2
local ACCEPTANCE_STORE_PREFIX = "RVTT_ProductionLeaseAcceptance_"
local ACCEPTANCE_KEY_PREFIX = "acceptance:production-lease:"

local diagnostics = Diagnostics.new()
local registry = CommandRegistry.new()
local outbox = EventOutbox.new()
local journal = SnapshotJournal.new(512)
local transactions = TransactionCoordinator.new(diagnostics)
local runtime = AuthorityRuntime.new(registry, transactions, outbox, diagnostics, journal)

for _, domain in ServiceGraph.domainModules() do
	runtime:installDomain(domain)
end

local projectRoot = ServerStorage:WaitForChild("RVTT")

local function projectBoolFlag(name: string): boolean
	local flag = projectRoot:FindFirstChild(name)
	return flag ~= nil and flag:IsA("BoolValue") and flag.Value
end

local function projectStringValue(name: string, fallback: string): string
	local value = projectRoot:FindFirstChild(name)
	if value ~= nil and value:IsA("StringValue") and value.Value ~= "" then
		return value.Value
	end
	return fallback
end

local function projectNumberValue(name: string, fallback: number): number
	local value = projectRoot:FindFirstChild(name)
	if
		value ~= nil
		and (value:IsA("NumberValue") or value:IsA("IntValue"))
		and value.Value > 0
	then
		return value.Value
	end
	return fallback
end

local AUTHORITY_STORE_NAME = projectStringValue(
	"AuthorityStoreName",
	DEFAULT_AUTHORITY_STORE_NAME
)
local AUTHORITY_KEY = projectStringValue("AuthorityKey", DEFAULT_AUTHORITY_KEY)
local LEASE_STORE_NAME = projectStringValue("LeaseStoreName", DEFAULT_LEASE_STORE_NAME)
local LEASE_TTL_SECONDS = projectNumberValue("LeaseTtlSeconds", DEFAULT_LEASE_TTL_SECONDS)
local LEASE_RENEW_INTERVAL_SECONDS = projectNumberValue(
	"LeaseRenewIntervalSeconds",
	DEFAULT_LEASE_RENEW_INTERVAL_SECONDS
)
local LEASE_RETRY_INTERVAL_SECONDS = projectNumberValue(
	"LeaseRetryIntervalSeconds",
	DEFAULT_LEASE_RETRY_INTERVAL_SECONDS
)
local LEASE_OWNER_ID_OVERRIDE = projectStringValue("LeaseOwnerId", "")
local PRODUCTION_LEASE_ACCEPTANCE_PHASE = projectStringValue(
	"ProductionLeaseAcceptancePhase",
	""
)
local PRODUCTION_LEASE_ACCEPTANCE_META_KEY = AUTHORITY_KEY .. ":meta"
local productionLeaseAcceptanceEnabled = PRODUCTION_LEASE_ACCEPTANCE_PHASE ~= ""

local function startsWith(value: string, prefix: string): boolean
	return string.sub(value, 1, #prefix) == prefix
end

if productionLeaseAcceptanceEnabled then
	assert(RunService:IsStudio(), "production lease acceptance is Studio-only")
	assert(
		PRODUCTION_LEASE_ACCEPTANCE_PHASE == "seed"
			or PRODUCTION_LEASE_ACCEPTANCE_PHASE == "verify",
		"unknown production lease acceptance phase"
	)
	assert(
		startsWith(AUTHORITY_STORE_NAME, ACCEPTANCE_STORE_PREFIX),
		"production lease acceptance requires a safe authority store"
	)
	assert(
		startsWith(LEASE_STORE_NAME, ACCEPTANCE_STORE_PREFIX),
		"production lease acceptance requires a safe lease store"
	)
	assert(
		startsWith(AUTHORITY_KEY, ACCEPTANCE_KEY_PREFIX),
		"production lease acceptance requires a safe authority key"
	)
	assert(
		startsWith(LEASE_OWNER_ID_OVERRIDE, ACCEPTANCE_KEY_PREFIX),
		"production lease acceptance requires a safe owner id"
	)
end

local function setStatus(name: string, value: any)
	projectRoot:SetAttribute(name, value)
end

local function updateAuthorityStatus(state: any)
	setStatus("ProductionLeaseAuthorityRevision", state.revision)
	setStatus("ProductionLeaseAuthorityEpoch", state.authorityEpoch)
end

setStatus("ProductionLeaseAcceptancePhase", PRODUCTION_LEASE_ACCEPTANCE_PHASE)
setStatus("ProductionLeaseAcceptanceChecksPassed", false)
setStatus("ProductionLeaseAcceptanceStaleBlocked", false)
setStatus("ProductionLeasePersistenceReady", false)
setStatus("ProductionLeasePersistenceStartupCode", "")
setStatus("ProductionLeaseLeaseActive", false)
setStatus("ProductionLeaseLeaseFencingToken", 0)
setStatus("ProductionLeaseLeaseOwnerId", "")
setStatus("ProductionLeaseLeaseToken", "")
updateAuthorityStatus(runtime:snapshot())

local slice01AcceptanceMode = projectBoolFlag("Slice01AcceptanceMode")
if slice01AcceptanceMode then
	print("[RVTT Slice01] acceptance role override enabled")
end

local remotes = RemoteBootstrap.create()
local function roleResolver(player: Player): string
	if slice01AcceptanceMode then
		return "dm"
	end
	if game.PrivateServerOwnerId ~= 0 and player.UserId == game.PrivateServerOwnerId then
		return "dm"
	end
	local role = player:GetAttribute("RVTT_Role")
	if role == "dm" or role == "observer" then
		return role
	end
	return "player"
end

local builder = ProjectionBuilder.new()
local publisher: any = ProjectionPublisher.new(runtime, builder, remotes, roleResolver, nil)

local persistenceAttributeEnabled = game:GetAttribute("RVTT_EnableStudioPersistence") == true
local persistenceProjectEnabled = projectBoolFlag("EnableStudioPersistence")
local studioPersistenceEnabled = persistenceAttributeEnabled or persistenceProjectEnabled
local persistenceActivationSource = "disabled"
if persistenceAttributeEnabled then
	persistenceActivationSource = "attribute"
elseif persistenceProjectEnabled then
	persistenceActivationSource = "project-config"
end

local persistenceEnabled = not RunService:IsStudio() or studioPersistenceEnabled
local persistence: any = nil
local leaseOwnership: any = nil
local persistenceReady = false
local persistenceStartupFailure: any = nil
local commandGuard: any = nil
local leaseCoordinator: any = nil
local ownerId = ""

local function persistenceFailure(reason: string): any
	return Result.err(
		"PERSISTENCE_FAILED",
		"error.persistence.failed",
		true,
		{ reason = reason } :: { [string]: unknown }
	)
end

local function removeAcceptanceData(): any
	local ok, failure = pcall(function()
		local authorityStore = DataStoreService:GetDataStore(AUTHORITY_STORE_NAME)
		local leaseStore = DataStoreService:GetDataStore(LEASE_STORE_NAME)
		authorityStore:RemoveAsync(AUTHORITY_KEY)
		authorityStore:RemoveAsync(PRODUCTION_LEASE_ACCEPTANCE_META_KEY)
		leaseStore:RemoveAsync(AUTHORITY_KEY)
	end)
	if not ok then
		return persistenceFailure(tostring(failure))
	end
	return Result.ok(true)
end

if persistenceEnabled then
	print(
		string.format(
			"[RVTT Persistence] enabled gameId=%d placeId=%d studio=%s source=%s store=%s key=%s",
			game.GameId,
			game.PlaceId,
			tostring(RunService:IsStudio()),
			persistenceActivationSource,
			AUTHORITY_STORE_NAME,
			AUTHORITY_KEY
		)
	)

	if
		productionLeaseAcceptanceEnabled
		and PRODUCTION_LEASE_ACCEPTANCE_PHASE == "seed"
	then
		local cleanupResult = removeAcceptanceData()
		if not cleanupResult.ok then
			persistenceStartupFailure = cleanupResult
			diagnostics:record("error", "PRODUCTION_LEASE_ACCEPTANCE_CLEANUP_FAILED", {
				code = cleanupResult.error.code,
			})
		end
	end

	local migrations = MigrationRegistry.new(Version.SCHEMA)
	local migrationModule = projectRoot.Migrations:WaitForChild("001_InitialSchema")
	migrations:register(0, require(migrationModule))
	local profileStore = ProfileStore.new(AUTHORITY_STORE_NAME, migrations, diagnostics)
	ownerId = if LEASE_OWNER_ID_OVERRIDE ~= ""
		then LEASE_OWNER_ID_OVERRIDE
		elseif game.JobId ~= "" then "job:" .. game.JobId
		else "studio:" .. HttpService:GenerateGUID(false)
	local leaseStore = LeaseStore.new(LEASE_STORE_NAME, diagnostics)
	leaseCoordinator =
		LeaseCoordinator.new(leaseStore, AUTHORITY_KEY, ownerId, LEASE_TTL_SECONDS, diagnostics)
	leaseOwnership = LeaseOwnership.new(leaseCoordinator, diagnostics, {
		renewIntervalSeconds = LEASE_RENEW_INTERVAL_SECONDS,
		retryIntervalSeconds = LEASE_RETRY_INTERVAL_SECONDS,
	})

	if persistenceStartupFailure == nil then
		local acquireResult = leaseOwnership:acquire()
		if acquireResult.ok then
			local fenceResult = leaseOwnership:writeFence()
			if fenceResult.ok then
				setStatus("ProductionLeaseLeaseOwnerId", fenceResult.value.ownerId)
				setStatus("ProductionLeaseLeaseToken", fenceResult.value.token)
				setStatus("ProductionLeaseLeaseFencingToken", fenceResult.value.fencingToken)
				setStatus("ProductionLeaseLeaseActive", true)
			end

			local protectedStore = LeaseProtectedStore.new(
				profileStore,
				leaseOwnership,
				diagnostics,
				runtime:snapshot()
			)
			persistence = PersistenceCoordinator.new(protectedStore, AUTHORITY_KEY, diagnostics)
			local loadResult = persistence:load()
			if loadResult.ok then
				if loadResult.value ~= nil then
					local restoreResult = runtime:restore(loadResult.value)
					if restoreResult.ok then
						persistenceReady = true
					else
						persistenceStartupFailure = restoreResult
						diagnostics:record("error", "AUTHORITY_RESTORE_FAILED", {
							code = restoreResult.error.code,
						})
					end
				else
					persistenceReady = true
				end
			else
				persistenceStartupFailure = loadResult
				diagnostics:record("warning", "PERSISTENCE_DEGRADED", {
					code = loadResult.error.code,
				})
			end

			updateAuthorityStatus(runtime:snapshot())
			setStatus("ProductionLeaseStartupRevision", runtime:snapshot().revision)
			setStatus("ProductionLeaseStartupEpoch", runtime:snapshot().authorityEpoch)
			setStatus("ProductionLeasePersistenceReady", persistenceReady)

			if persistenceReady then
				runtime:onCommitted(function(state)
					updateAuthorityStatus(state)
					persistence:markDirty(state)
				end)
				leaseOwnership:startRenewal()
				print(
					string.format(
						"[RVTT Lease] result=ACTIVE owner=%s fence=%s expiresAt=%s",
						ownerId,
						tostring(leaseCoordinator:fencingToken()),
						tostring(leaseCoordinator:expiresAt())
					)
				)
			else
				leaseOwnership:beginShutdown()
				local releaseResult = leaseOwnership:release()
				setStatus("ProductionLeaseLeaseActive", false)
				if not releaseResult.ok then
					diagnostics:record("warning", "PERSISTENCE_STARTUP_LEASE_RELEASE_FAILED", {
						code = releaseResult.error.code,
					})
				end
			end
		else
			persistenceStartupFailure = acquireResult
			diagnostics:record("warning", "PERSISTENCE_LEASE_UNAVAILABLE", {
				code = acquireResult.error.code,
			})
		end
	end

	if persistenceStartupFailure ~= nil then
		setStatus("ProductionLeasePersistenceStartupCode", persistenceStartupFailure.error.code)
	end

	commandGuard = function(_context: any, _envelope: any): any
		if persistenceStartupFailure ~= nil then
			return persistenceStartupFailure
		end
		if leaseOwnership == nil then
			return Result.err("LEASE_NOT_HELD", "error.persistence.lease_not_held", false)
		end
		local leaseResult = leaseOwnership:guardLocal()
		if not leaseResult.ok then
			setStatus("ProductionLeaseLeaseActive", false)
			diagnostics:increment("command.lease_blocked")
			return leaseResult
		end
		if not persistenceReady then
			return Result.err("PERSISTENCE_NOT_READY", "error.persistence.not_ready", true)
		end
		return Result.ok(true)
	end

	game:BindToClose(function()
		local acceptanceChecksPassed =
			projectRoot:GetAttribute("ProductionLeaseAcceptanceChecksPassed") == true
		local acceptanceStaleBlocked =
			projectRoot:GetAttribute("ProductionLeaseAcceptanceStaleBlocked") == true
		local shutdownSnapshot = runtime:snapshot()
		local shutdownFence: any = nil
		local flushOk = persistence == nil or not persistenceReady
		local metadataOk = not productionLeaseAcceptanceEnabled
			or PRODUCTION_LEASE_ACCEPTANCE_PHASE ~= "seed"
		local releaseOk = leaseOwnership == nil
		local cleanupOk = not productionLeaseAcceptanceEnabled
			or PRODUCTION_LEASE_ACCEPTANCE_PHASE ~= "verify"

		if leaseOwnership ~= nil and leaseOwnership:isActive() then
			local fenceResult = leaseOwnership:writeFence()
			if fenceResult.ok then
				shutdownFence = fenceResult.value
			end
			leaseOwnership:beginShutdown()
		end
		if persistence ~= nil and persistenceReady then
			local result = persistence:flushUntilClean()
			flushOk = result.ok
			if not result.ok then
				diagnostics:record("error", "PERSISTENCE_SHUTDOWN_FLUSH_FAILED", {
					code = result.error.code,
				})
			end
		end

		if
			productionLeaseAcceptanceEnabled
			and PRODUCTION_LEASE_ACCEPTANCE_PHASE == "seed"
			and flushOk
			and shutdownFence ~= nil
		then
			local ok, failure = pcall(function()
				DataStoreService:GetDataStore(AUTHORITY_STORE_NAME):SetAsync(
					PRODUCTION_LEASE_ACCEPTANCE_META_KEY,
					{
						ownerId = shutdownFence.ownerId,
						token = shutdownFence.token,
						fencingToken = shutdownFence.fencingToken,
						revision = shutdownSnapshot.revision,
						authorityEpoch = shutdownSnapshot.authorityEpoch,
						checksPassed = acceptanceChecksPassed,
					}
				)
			end)
			metadataOk = ok
			if not ok then
				diagnostics:record("error", "PRODUCTION_LEASE_ACCEPTANCE_META_SAVE_FAILED", {
					reason = tostring(failure),
				})
			end
		end

		if leaseOwnership ~= nil and leaseOwnership:isActive() then
			local releaseResult = leaseOwnership:release()
			releaseOk = releaseResult.ok
			setStatus("ProductionLeaseLeaseActive", false)
			if not releaseResult.ok then
				diagnostics:record("error", "PERSISTENCE_SHUTDOWN_LEASE_RELEASE_FAILED", {
					code = releaseResult.error.code,
				})
			end
		end

		if
			productionLeaseAcceptanceEnabled
			and PRODUCTION_LEASE_ACCEPTANCE_PHASE == "verify"
		then
			local cleanupResult = removeAcceptanceData()
			cleanupOk = cleanupResult.ok
			if not cleanupResult.ok then
				diagnostics:record("error", "PRODUCTION_LEASE_ACCEPTANCE_CLEANUP_FAILED", {
					code = cleanupResult.error.code,
				})
			end
		end

		if productionLeaseAcceptanceEnabled then
			local failed = 0
			if not acceptanceChecksPassed then
				failed += 1
			end
			if not flushOk then
				failed += 1
			end
			if not metadataOk then
				failed += 1
			end
			if not releaseOk then
				failed += 1
			end
			if not cleanupOk then
				failed += 1
			end
			if PRODUCTION_LEASE_ACCEPTANCE_PHASE == "verify" and not acceptanceStaleBlocked then
				failed += 1
			end
			local resultName = if failed == 0 then "PASS" else "FAIL"
			local label = if PRODUCTION_LEASE_ACCEPTANCE_PHASE == "seed"
				then "[RVTT Production Lease Seed]"
				else "[RVTT Production Lease Verify]"
			print(
				string.format(
					"%s result=%s failed=%d checks=%s flush=%s metadata=%s release=%s cleanup=%s staleBlocked=%s revision=%d fence=%s owner=%s",
					label,
					resultName,
					failed,
					tostring(acceptanceChecksPassed),
					tostring(flushOk),
					tostring(metadataOk),
					tostring(releaseOk),
					tostring(cleanupOk),
					tostring(acceptanceStaleBlocked),
					shutdownSnapshot.revision,
					tostring(if shutdownFence ~= nil then shutdownFence.fencingToken else nil),
					ownerId
				)
			)
			assert(failed == 0, "RVTT production lease acceptance failed")
		end
	end)
else
	diagnostics:record("info", "STUDIO_PERSISTENCE_DISABLED", {})
	print(
		"[RVTT Boot] Studio persistence disabled; build persistence-acceptance.project.json or set RVTT_EnableStudioPersistence=true"
	)
end

local router: any = CommandRouter.new(
	runtime,
	remotes,
	RateLimiter.new(1, 30),
	roleResolver,
	publisher,
	diagnostics,
	nil,
	commandGuard
)

publisher:start()
remotes.clientReady.OnServerEvent:Connect(function(player)
	publisher:publish(player)
end)
router:start()

local function removeRobloxAvatar(player: Player)
	local character = player.Character
	if character ~= nil then
		character:Destroy()
	end
end

local function executeSystemCommand(commandType: string, payload: { [string]: unknown }): any
	if commandGuard ~= nil then
		local guardResult = commandGuard(nil, nil)
		if not guardResult.ok then
			diagnostics:record(
				"warning",
				"SYSTEM_COMMAND_LEASE_BLOCKED",
				{
					commandType = commandType,
					code = guardResult.error.code,
				} :: { [string]: unknown }
			)
			return guardResult
		end
	end
	return runtime:executeSystem(commandType, payload)
end

local function recordConnected(player: Player)
	removeRobloxAvatar(player)
	executeSystemCommand("session.connection", { userId = player.UserId, status = "connected" })
end

Players.PlayerAdded:Connect(recordConnected)
Players.PlayerRemoving:Connect(function(player)
	executeSystemCommand("session.connection", { userId = player.UserId, status = "disconnected" })
end)
for _, player in Players:GetPlayers() do
	recordConnected(player)
end
publisher:publishAll()

diagnostics:record(
	"info",
	"SERVER_BOOTED",
	{
		commandCount = #registry:list(),
		leaseActive = leaseOwnership ~= nil and leaseOwnership:isActive(),
		persistenceEnabled = persistenceEnabled,
		persistenceReady = persistenceReady,
		persistenceActivationSource = persistenceActivationSource,
		productionLeaseAcceptancePhase = PRODUCTION_LEASE_ACCEPTANCE_PHASE,
		robloxCharacterAutoLoads = Players.CharacterAutoLoads,
		slice01AcceptanceMode = slice01AcceptanceMode,
	} :: { [string]: unknown }
)
