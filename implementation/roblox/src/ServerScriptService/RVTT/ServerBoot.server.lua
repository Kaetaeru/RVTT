--!strict

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

local Version = require(ReplicatedStorage.RVTT.Shared.Core.Version)
local Server = script.Parent.Server
local CommandRegistry = require(Server.Runtime.CommandRegistry)
local Diagnostics = require(Server.Runtime.Diagnostics)
local EventOutbox = require(Server.Runtime.EventOutbox)
local TransactionCoordinator = require(Server.Runtime.TransactionCoordinator)
local AuthorityRuntime = require(Server.Runtime.AuthorityRuntime)
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

local diagnostics = Diagnostics.new()
local registry = CommandRegistry.new()
local outbox = EventOutbox.new()
local journal = SnapshotJournal.new(512)
local transactions = TransactionCoordinator.new(diagnostics)
local runtime = AuthorityRuntime.new(registry, transactions, outbox, diagnostics, journal)

for _, domain in ServiceGraph.domainModules() do
	runtime:installDomain(domain)
end

local remotes = RemoteBootstrap.create()
local function roleResolver(player: Player): string
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
local router: any = CommandRouter.new(
	runtime,
	remotes,
	RateLimiter.new(1, 30),
	roleResolver,
	publisher,
	diagnostics,
	nil
)

publisher:start()
remotes.clientReady.OnServerEvent:Connect(function(player)
	publisher:publish(player)
end)

local studioPersistenceEnabled = game:GetAttribute("RVTT_EnableStudioPersistence") == true
local persistenceEnabled = not RunService:IsStudio() or studioPersistenceEnabled
if persistenceEnabled then
	local migrations = MigrationRegistry.new(Version.SCHEMA)
	local migrationModule = ServerStorage.RVTT.Migrations:WaitForChild("001_InitialSchema")
	migrations:register(0, require(migrationModule))
	local store = ProfileStore.new("RVTT_Authority_v1", migrations, diagnostics)
	local persistence = PersistenceCoordinator.new(store, "campaign:default", diagnostics)
	local loadResult = persistence:load()
	if loadResult.ok and loadResult.value ~= nil then
		local restoreResult = runtime:restore(loadResult.value)
		if not restoreResult.ok then
			diagnostics:record("error", "AUTHORITY_RESTORE_FAILED", {})
		end
	elseif not loadResult.ok then
		diagnostics:record("warning", "PERSISTENCE_DEGRADED", {})
	end
	runtime:onCommitted(function(state)
		persistence:markDirty(state)
	end)

	game:BindToClose(function()
		local result = persistence:flushUntilClean()
		if not result.ok then
			diagnostics:record("error", "PERSISTENCE_SHUTDOWN_FLUSH_FAILED", {})
		end
	end)
else
	diagnostics:record("info", "STUDIO_PERSISTENCE_DISABLED", {})
	print(
		"[RVTT Boot] Studio persistence disabled; use live-datastore.project.json or set RVTT_EnableStudioPersistence=true"
	)
end

router:start()

local function recordConnected(player: Player)
	runtime:executeSystem("session.connection", { userId = player.UserId, status = "connected" })
end

Players.PlayerAdded:Connect(recordConnected)
Players.PlayerRemoving:Connect(function(player)
	runtime:executeSystem("session.connection", { userId = player.UserId, status = "disconnected" })
end)
for _, player in Players:GetPlayers() do
	recordConnected(player)
end
publisher:publishAll()

diagnostics:record(
	"info",
	"SERVER_BOOTED",
	{ commandCount = #registry:list(), persistenceEnabled = persistenceEnabled } :: { [string]: unknown }
)
