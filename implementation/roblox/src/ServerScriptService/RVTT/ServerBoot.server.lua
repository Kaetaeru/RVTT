--!strict

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

local AUTHORITY_STORE_NAME = "RVTT_Authority_v1"
local AUTHORITY_KEY = "campaign:default"
local LEASE_STORE_NAME = "RVTT_AuthorityLease_v1"
local LEASE_TTL_SECONDS = 30
local LEASE_RENEW_INTERVAL_SECONDS = 10
local LEASE_RETRY_INTERVAL_SECONDS = 2

local diagnostics = Diagnostics.new()
local registry = CommandRegistry.new()
local outbox = EventOutbox.new()
local journal = SnapshotJournal.new(512)
local transactions = TransactionCoordinator.new(diagnostics)
local runtime = AuthorityRuntime.new(registry, transactions, outbox, diagnostics, journal)

for _, domain in ServiceGraph.domainModules() do
	runtime:installDomain(domain)
end

local function projectBoolFlag(name: string): boolean
	local flag = ServerStorage.RVTT:FindFirstChild(name)
	return flag ~= nil and flag:IsA("BoolValue") and flag.Value
end

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

if persistenceEnabled then
	print(
		string.format(
			"[RVTT Persistence] enabled gameId=%d placeId=%d studio=%s source=%s",
			game.GameId,
			game.PlaceId,
			tostring(RunService:IsStudio()),
			persistenceActivationSource
		)
	)

	local migrations = MigrationRegistry.new(Version.SCHEMA)
	local migrationModule = ServerStorage.RVTT.Migrations:WaitForChild("001_InitialSchema")
	migrations:register(0, require(migrationModule))
	local profileStore = ProfileStore.new(AUTHORITY_STORE_NAME, migrations, diagnostics)
	local ownerId = if game.JobId ~= ""
		then "job:" .. game.JobId
		else "studio:" .. HttpService:GenerateGUID(false)
	local leaseStore = LeaseStore.new(LEASE_STORE_NAME, diagnostics)
	local leaseCoordinator =
		LeaseCoordinator.new(leaseStore, AUTHORITY_KEY, ownerId, LEASE_TTL_SECONDS, diagnostics)
	leaseOwnership = LeaseOwnership.new(leaseCoordinator, diagnostics, {
		renewIntervalSeconds = LEASE_RENEW_INTERVAL_SECONDS,
		retryIntervalSeconds = LEASE_RETRY_INTERVAL_SECONDS,
	})

	local acquireResult = leaseOwnership:acquire()
	if acquireResult.ok then
		local protectedStore = LeaseProtectedStore.new(profileStore, leaseOwnership, diagnostics)
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

		if persistenceReady then
			runtime:onCommitted(function(state)
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

	commandGuard = function(_context: any, _envelope: any): any
		if persistenceStartupFailure ~= nil then
			return persistenceStartupFailure
		end
		if leaseOwnership == nil then
			return Result.err("LEASE_NOT_HELD", "error.persistence.lease_not_held", false)
		end
		local leaseResult = leaseOwnership:guardLocal()
		if not leaseResult.ok then
			diagnostics:increment("command.lease_blocked")
			return leaseResult
		end
		if not persistenceReady then
			return Result.err("PERSISTENCE_NOT_READY", "error.persistence.not_ready", true)
		end
		return Result.ok(true)
	end

	game:BindToClose(function()
		if leaseOwnership ~= nil then
			leaseOwnership:beginShutdown()
		end
		if persistence ~= nil and persistenceReady then
			local result = persistence:flushUntilClean()
			if not result.ok then
				diagnostics:record("error", "PERSISTENCE_SHUTDOWN_FLUSH_FAILED", {
					code = result.error.code,
				})
			end
		end
		if leaseOwnership ~= nil and leaseOwnership:isActive() then
			local releaseResult = leaseOwnership:release()
			if not releaseResult.ok then
				diagnostics:record("error", "PERSISTENCE_SHUTDOWN_LEASE_RELEASE_FAILED", {
					code = releaseResult.error.code,
				})
			end
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
		robloxCharacterAutoLoads = Players.CharacterAutoLoads,
		slice01AcceptanceMode = slice01AcceptanceMode,
	} :: { [string]: unknown }
)
