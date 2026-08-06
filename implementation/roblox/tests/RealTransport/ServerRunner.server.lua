--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local testMode = ReplicatedStorage:FindFirstChild("RVTT_TestMode")
if testMode == nil or not testMode:IsA("StringValue") or testMode.Value ~= "real-transport" then
	return
end

local REQUIRED_CLIENTS = 3
local INITIAL_TIMEOUT_SECONDS = 45
local TRANSITION_TIMEOUT_SECONDS = 180
local ROLE_ORDER: { string } = { "dm", "player", "observer" }
local TEST_USER_IDS: { [string]: number } = {
	dm = 2101,
	player = 2102,
	observer = 2103,
}
local TARGET_ROLE = "player"

local function ensure(className: string, parent: Instance, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing ~= nil then
		assert(existing.ClassName == className, "real transport remote class mismatch: " .. name)
		return existing
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local coordination = ensure("Folder", ReplicatedStorage, "RVTT_RealTransport") :: Folder
local control = ensure("RemoteEvent", coordination, "Control") :: RemoteEvent
local reportRemote = ensure("RemoteEvent", coordination, "Report") :: RemoteEvent

local Server = ServerScriptService.RVTT.Server
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
local journal = SnapshotJournal.new(128)
local transactions = TransactionCoordinator.new(diagnostics)
local runtime = AuthorityRuntime.new(registry, transactions, outbox, diagnostics, journal)
for _, domain in ServiceGraph.domainModules() do
	runtime:installDomain(domain)
end

local roleByPlayer: { [Player]: string } = {}
local generationByPlayer: { [Player]: number } = {}
local activeByRole: { [string]: Player? } = {}
local generationByRole: { [string]: number } = {
	dm = 0,
	player = 0,
	observer = 0,
}
local initialSlotsAssigned = 0
local reconnectExpected = false
local disconnectedPlayer: Player? = nil
local reconnectedPlayer: Player? = nil
local targetRemoved = false

local function roleResolver(player: Player): string
	return roleByPlayer[player] or "observer"
end

local function playerIdResolver(player: Player): number
	local role = roleByPlayer[player]
	return if role ~= nil then TEST_USER_IDS[role] else 2999
end

local remotes = RemoteBootstrap.create()
local builder = ProjectionBuilder.new()
local publisher: any =
	ProjectionPublisher.new(runtime, builder, remotes, roleResolver, playerIdResolver)
local router: any = CommandRouter.new(
	runtime,
	remotes,
	RateLimiter.new(1, 100),
	roleResolver,
	publisher,
	diagnostics,
	playerIdResolver
)
publisher:start()
router:start()

local function setInactive(player: Player)
	player:SetAttribute("RVTT_TransportActive", false)
end

local function assign(player: Player)
	if player:GetAttribute("RVTT_TransportActive") ~= nil then
		return
	end

	local role: string? = nil
	if reconnectExpected and activeByRole[TARGET_ROLE] == nil then
		role = TARGET_ROLE
		generationByRole[TARGET_ROLE] += 1
		reconnectExpected = false
		reconnectedPlayer = player
	elseif initialSlotsAssigned < REQUIRED_CLIENTS then
		initialSlotsAssigned += 1
		role = ROLE_ORDER[initialSlotsAssigned]
	else
		setInactive(player)
		return
	end

	local assignedRole = role :: string
	roleByPlayer[player] = assignedRole
	generationByPlayer[player] = generationByRole[assignedRole]
	activeByRole[assignedRole] = player
	player:SetAttribute("RVTT_TransportActive", true)
	player:SetAttribute("RVTT_Role", assignedRole)
	player:SetAttribute("RVTT_TestUserId", TEST_USER_IDS[assignedRole])
	player:SetAttribute("RVTT_ReconnectGeneration", generationByRole[assignedRole])

	local connected = runtime:executeSystem("session.connection", {
		userId = TEST_USER_IDS[assignedRole],
		status = "connected",
	})
	if not connected.ok then
		warn("[RVTT Real Transport] connection commit failed role=" .. assignedRole)
	end
	publisher:publishAll()
end

Players.PlayerAdded:Connect(assign)
Players.PlayerRemoving:Connect(function(player)
	local role = roleByPlayer[player]
	if role == nil then
		return
	end
	activeByRole[role] = nil
	local disconnected = runtime:executeSystem("session.connection", {
		userId = TEST_USER_IDS[role],
		status = "disconnected",
	})
	if not disconnected.ok then
		warn("[RVTT Real Transport] disconnect commit failed role=" .. role)
	end
	publisher:publishAll()
	if role == TARGET_ROLE then
		disconnectedPlayer = player
		targetRemoved = true
		reconnectExpected = true
		print("[RVTT Real Transport Prompt] action=start-replacement-client role=player")
	end
end)
for _, player in Players:GetPlayers() do
	assign(player)
end

local reports: { [string]: { [string]: any } } = {}
local function reportKey(role: string, generation: number): string
	return string.format("%s:%d", role, generation)
end

reportRemote.OnServerEvent:Connect(function(player, message)
	local role = roleByPlayer[player]
	local generation = generationByPlayer[player]
	if role == nil or generation == nil or type(message) ~= "table" then
		return
	end
	if
		message.role ~= role
		or message.testUserId ~= TEST_USER_IDS[role]
		or message.reconnectGeneration ~= generation
	then
		return
	end
	local phase = message.phase
	if type(phase) ~= "string" then
		return
	end
	local phaseReports = reports[phase]
	if phaseReports == nil then
		phaseReports = {}
		reports[phase] = phaseReports
	end
	phaseReports[reportKey(role, generation)] = message
end)

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

local function countEntries(value: any): number
	if type(value) ~= "table" then
		return 0
	end
	local count = 0
	for _ in value do
		count += 1
	end
	return count
end

local function waitUntil(predicate: () -> boolean, timeoutSeconds: number): boolean
	local deadline = os.clock() + timeoutSeconds
	while os.clock() < deadline do
		if predicate() then
			return true
		end
		task.wait(0.05)
	end
	return false
end

local function reportFor(phase: string, role: string, generation: number): any
	local phaseReports = reports[phase]
	return if phaseReports ~= nil then phaseReports[reportKey(role, generation)] else nil
end

local function activeCount(): number
	return countEntries(activeByRole)
end

local function finish(reconnects: number)
	local snapshot = runtime:snapshot()
	print(
		string.format(
			"[RVTT Real Transport] result=%s passed=%d failed=%d initialClients=%d reconnects=%d revision=%d epoch=%s",
			if failed == 0 then "PASS" else "FAIL",
			passed,
			failed,
			REQUIRED_CLIENTS,
			reconnects,
			snapshot.revision,
			snapshot.authorityEpoch
		)
	)
	for _, failure in failures do
		warn("[RVTT Real Transport]", failure)
	end
	assert(failed == 0, "RVTT real transport acceptance failed")
end

task.spawn(function()
	local initialConnected = waitUntil(function()
		return activeCount() == REQUIRED_CLIENTS
	end, INITIAL_TIMEOUT_SECONDS)
	expect(initialConnected, "start a Local Server with exactly three clients")
	if not initialConnected then
		finish(0)
		return
	end

	for _, role in ROLE_ORDER do
		local ready = waitUntil(function()
			return reportFor("ready", role, 0) ~= nil
		end, INITIAL_TIMEOUT_SECONDS)
		expect(ready, role .. " client reports initial readiness")
	end
	if failed > 0 then
		finish(0)
		return
	end

	control:FireAllClients({ phase = "join" })
	for _, role in ROLE_ORDER do
		local joined = waitUntil(function()
			return reportFor("join", role, 0) ~= nil
		end, INITIAL_TIMEOUT_SECONDS)
		expect(joined, role .. " client completes initial join")
		local message = reportFor("join", role, 0)
		expect(message ~= nil and message.ok == true, role .. " initial join succeeds")
	end
	if failed > 0 then
		finish(0)
		return
	end

	local initialSnapshot = runtime:snapshot()
	local initialEpoch = initialSnapshot.authorityEpoch
	local revisionBeforeDisconnect = initialSnapshot.revision
	local sessionBefore = initialSnapshot.domains.session
	equal(
		countEntries(sessionBefore.memberships),
		3,
		"initial server has exactly three memberships"
	)
	equal(activeCount(), 3, "initial server has one active player per role")

	local target = activeByRole[TARGET_ROLE]
	expect(target ~= nil, "target player client exists")
	if target == nil then
		finish(0)
		return
	end
	control:FireClient(target, { phase = "prepare_disconnect" })
	local disconnectReady = waitUntil(function()
		return reportFor("disconnect_ready", TARGET_ROLE, 0) ~= nil
	end, INITIAL_TIMEOUT_SECONDS)
	expect(disconnectReady, "target player acknowledges disconnect instruction")
	print("[RVTT Real Transport Prompt] action=close-client role=player")

	local removed = waitUntil(function()
		return targetRemoved
	end, TRANSITION_TIMEOUT_SECONDS)
	expect(removed, "closing the player client fires PlayerRemoving")
	if not removed then
		finish(0)
		return
	end

	local disconnectedSnapshot = runtime:snapshot()
	local disconnectedSession = disconnectedSnapshot.domains.session
	equal(
		disconnectedSession.connections[tostring(TEST_USER_IDS.player)],
		"disconnected",
		"PlayerRemoving records disconnected authority state"
	)
	equal(
		countEntries(disconnectedSession.memberships),
		3,
		"disconnect preserves the logical membership"
	)
	equal(activeCount(), 2, "disconnect removes only the physical player instance")
	expect(
		disconnectedSnapshot.revision > revisionBeforeDisconnect,
		"disconnect advances the authority revision"
	)

	local replacementArrived = waitUntil(function()
		return reconnectedPlayer ~= nil and activeByRole[TARGET_ROLE] == reconnectedPlayer
	end, TRANSITION_TIMEOUT_SECONDS)
	expect(replacementArrived, "starting one replacement client fires PlayerAdded")
	if not replacementArrived then
		finish(0)
		return
	end
	expect(
		not rawequal(reconnectedPlayer, disconnectedPlayer),
		"reconnect uses a new Roblox Player instance"
	)

	local reconnectReady = waitUntil(function()
		return reportFor("ready", TARGET_ROLE, 1) ~= nil
	end, INITIAL_TIMEOUT_SECONDS)
	expect(reconnectReady, "replacement client reports readiness with generation one")
	local replacement = activeByRole[TARGET_ROLE]
	if replacement ~= nil then
		control:FireClient(replacement, { phase = "validate_reconnect" })
	end
	local reconnectReported = waitUntil(function()
		return reportFor("reconnect", TARGET_ROLE, 1) ~= nil
	end, INITIAL_TIMEOUT_SECONDS)
	expect(reconnectReported, "replacement client completes reconnect validation")

	local reconnect = reportFor("reconnect", TARGET_ROLE, 1)
	expect(reconnect ~= nil and reconnect.ok == true, "same logical player rejoins successfully")
	if reconnect ~= nil then
		equal(reconnect.membershipCount, 3, "reconnect projection contains no duplicate membership")
		equal(reconnect.connection, "connected", "reconnect projection reports connected state")
		expect(reconnect.sequenceIncreasing == true, "reconnect full sync sequence increases")
		equal(reconnect.authorityEpoch, initialEpoch, "same server reconnect keeps authority epoch")
	end

	local finalSnapshot = runtime:snapshot()
	local finalSession = finalSnapshot.domains.session
	equal(countEntries(finalSession.memberships), 3, "server retains exactly three memberships")
	equal(
		finalSession.connections[tostring(TEST_USER_IDS.player)],
		"connected",
		"PlayerAdded restores connected authority state"
	)
	equal(activeCount(), 3, "replacement restores one active player per role")
	equal(finalSnapshot.authorityEpoch, initialEpoch, "reconnect does not rotate server epoch")
	expect(
		finalSnapshot.revision > disconnectedSnapshot.revision,
		"reconnect advances authority revision"
	)
	finish(1)
end)
