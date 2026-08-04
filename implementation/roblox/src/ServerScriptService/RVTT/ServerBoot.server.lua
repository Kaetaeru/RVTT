--!strict

local Server = script.Server
local CommandRegistry = require(Server.Runtime.CommandRegistry)
local Diagnostics = require(Server.Runtime.Diagnostics)
local EventOutbox = require(Server.Runtime.EventOutbox)
local TransactionCoordinator = require(Server.Runtime.TransactionCoordinator)
local AuthorityRuntime = require(Server.Runtime.AuthorityRuntime)
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
	return player:GetAttribute("RVTT_Role") or "player"
end

local builder = ProjectionBuilder.new()
local publisher = ProjectionPublisher.new(runtime, builder, remotes, roleResolver)
local router = CommandRouter.new(runtime, remotes, RateLimiter.new(1, 30), roleResolver, publisher, diagnostics)

publisher:start()
router:start()
remotes.clientReady.OnServerEvent:Connect(function(player)
	publisher:publish(player)
end)

diagnostics:record("info", "SERVER_BOOTED", { commandCount = #registry:list() })
