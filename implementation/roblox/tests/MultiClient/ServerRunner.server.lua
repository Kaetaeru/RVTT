--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local testMode = ReplicatedStorage:FindFirstChild("RVTT_TestMode")
if testMode == nil or not testMode:IsA("StringValue") or testMode.Value ~= "multi-client" then
	return
end

local REQUIRED_CLIENTS = 3
local PHASE_TIMEOUT_SECONDS = 30
local ROLE_ORDER = { "dm", "player", "observer" }
local TEST_USER_IDS = { 1001, 1002, 1003 }

local function ensure(className: string, parent: Instance, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing ~= nil then
		assert(existing.ClassName == className, "test remote class mismatch: " .. name)
		return existing
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local coordination = ensure("Folder", ReplicatedStorage, "RVTT_MultiClient") :: Folder
local control = ensure("RemoteEvent", coordination, "Control") :: RemoteEvent
local reportRemote = ensure("RemoteEvent", coordination, "Report") :: RemoteEvent

local activePlayers: { Player } = {}
local roleByPlayer: { [Player]: string } = {}
local testUserIdByPlayer: { [Player]: number } = {}

local function assignRole(player: Player)
	if player:GetAttribute("RVTT_MultiClientActive") ~= nil then
		return
	end
	local index = #activePlayers + 1
	if index > REQUIRED_CLIENTS then
		player:SetAttribute("RVTT_MultiClientActive", false)
		return
	end
	local role = ROLE_ORDER[index]
	local testUserId = TEST_USER_IDS[index]
	table.insert(activePlayers, player)
	roleByPlayer[player] = role
	testUserIdByPlayer[player] = testUserId
	player:SetAttribute("RVTT_MultiClientActive", true)
	player:SetAttribute("RVTT_Role", role)
	player:SetAttribute("RVTT_TestUserId", testUserId)
end

for _, player in Players:GetPlayers() do
	assignRole(player)
end
Players.PlayerAdded:Connect(assignRole)

local reports: { [string]: { [Player]: any } } = {}
reportRemote.OnServerEvent:Connect(function(player, message)
	if roleByPlayer[player] == nil or type(message) ~= "table" then
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
	message.serverRole = roleByPlayer[player]
	message.serverTestUserId = testUserIdByPlayer[player]
	phaseReports[player] = message
end)

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

local function roleResolver(player: Player): string
	return roleByPlayer[player] or "observer"
end

local function playerIdResolver(player: Player): number
	return testUserIdByPlayer[player] or 1999
end

local remotes = RemoteBootstrap.create()
local builder = ProjectionBuilder.new()
local publisher: any = ProjectionPublisher.new(
	runtime,
	builder,
	remotes,
	roleResolver,
	playerIdResolver
)
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

local passed = 0
local failed = 0
local failures: { string } = {}
local finished = false

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

local function waitForActivePlayers(): boolean
	local deadline = os.clock() + PHASE_TIMEOUT_SECONDS
	while os.clock() < deadline do
		if #activePlayers >= REQUIRED_CLIENTS then
			return true
		end
		task.wait(0.05)
	end
	return false
end

local function waitForReports(phase: string): boolean
	local deadline = os.clock() + PHASE_TIMEOUT_SECONDS
	while os.clock() < deadline do
		if countEntries(reports[phase]) >= REQUIRED_CLIENTS then
			return true
		end
		task.wait(0.05)
	end
	return false
end

local function reportForRole(phase: string, role: string): any
	local phaseReports = reports[phase]
	if phaseReports == nil then
		return nil
	end
	for player, message in phaseReports do
		if roleByPlayer[player] == role then
			return message
		end
	end
	return nil
end

local function playerForRole(role: string): Player?
	for player, assignedRole in roleByPlayer do
		if assignedRole == role then
			return player
		end
	end
	return nil
end

local function finish(staleRetries: number)
	if finished then
		return
	end
	finished = true
	print(
		string.format(
			"[RVTT MultiClient] passed=%d failed=%d clients=%d staleRetries=%d",
			passed,
			failed,
			#activePlayers,
			staleRetries
		)
	)
	for _, failure in failures do
		warn("[RVTT MultiClient]", failure)
	end
	assert(failed == 0, "RVTT multi-client tests failed")
end

task.spawn(function()
	local staleRetries = 0
	local playersConnected = waitForActivePlayers()
	expect(
		playersConnected,
		"start a Local Server with exactly three active clients before the timeout"
	)
	if not playersConnected then
		finish(staleRetries)
		return
	end

	local ready = waitForReports("ready")
	expect(ready, "all three clients report ready")
	if not ready then
		finish(staleRetries)
		return
	end

	local initialRevision: number? = nil
	for _, role in ROLE_ORDER do
		local message = reportForRole("ready", role)
		expect(message ~= nil, role .. " client receives its assigned role")
		if message ~= nil then
			equal(message.role, role, role .. " client role matches the server role")
			if initialRevision == nil then
				initialRevision = message.revision
			else
				equal(
					message.revision,
					initialRevision,
					"all clients begin from the same authority revision"
				)
			end
		end
	end
	equal(initialRevision, 0, "multi-client scenario starts at revision zero")

	control:FireAllClients({ phase = "concurrent_join" })
	local joined = waitForReports("join")
	expect(joined, "all clients finish the concurrent join phase")
	if not joined then
		finish(staleRetries)
		return
	end
	for _, role in ROLE_ORDER do
		local message = reportForRole("join", role)
		expect(message ~= nil and message.ok == true, role .. " eventually joins successfully")
		if message ~= nil then
			staleRetries += message.staleRetries or 0
		end
	end
	expect(staleRetries >= 2, "concurrent joins exercise stale-revision recovery")
	local session = runtime:snapshot().domains.session
	equal(countEntries(session.memberships), 3, "server commits exactly three memberships")
	equal(runtime:snapshot().revision, 3, "join retries do not duplicate commits")
	for _, player in activePlayers do
		local key = tostring(testUserIdByPlayer[player])
		equal(
			session.memberships[key].role,
			roleByPlayer[player],
			"membership role matches the authenticated viewer role"
		)
	end

	local revisionBeforeUnauthorized = runtime:snapshot().revision
	control:FireAllClients({ phase = "unauthorized" })
	local unauthorizedFinished = waitForReports("unauthorized")
	expect(unauthorizedFinished, "all clients finish the authorization phase")
	if not unauthorizedFinished then
		finish(staleRetries)
		return
	end
	local dmUnauthorized = reportForRole("unauthorized", "dm")
	local playerUnauthorized = reportForRole("unauthorized", "player")
	local observerUnauthorized = reportForRole("unauthorized", "observer")
	expect(dmUnauthorized ~= nil and dmUnauthorized.skipped == true, "DM skips the denial probe")
	expect(
		playerUnauthorized ~= nil and playerUnauthorized.errorCode == "UNAUTHORIZED",
		"player cannot execute a DM command"
	)
	expect(
		observerUnauthorized ~= nil and observerUnauthorized.errorCode == "UNAUTHORIZED",
		"observer cannot execute a DM command"
	)
	equal(
		runtime:snapshot().revision,
		revisionBeforeUnauthorized,
		"unauthorized commands do not change authority state"
	)

	local revisionBeforeDmAction = runtime:snapshot().revision
	control:FireAllClients({ phase = "dm_action" })
	local dmActionFinished = waitForReports("dm_action")
	expect(dmActionFinished, "all clients finish the DM action phase")
	if not dmActionFinished then
		finish(staleRetries)
		return
	end
	local dmAction = reportForRole("dm_action", "dm")
	expect(dmAction ~= nil and dmAction.ok == true, "DM command succeeds through RemoteEvent")
	equal(
		runtime:snapshot().revision,
		revisionBeforeDmAction + 1,
		"authorized DM command commits once"
	)

	control:FireAllClients({ phase = "create_draft" })
	local draftsFinished = waitForReports("create_draft")
	expect(draftsFinished, "all clients finish concurrent draft creation")
	if not draftsFinished then
		finish(staleRetries)
		return
	end
	local dmDraft = reportForRole("create_draft", "dm")
	local playerDraft = reportForRole("create_draft", "player")
	local observerDraft = reportForRole("create_draft", "observer")
	expect(dmDraft ~= nil and dmDraft.ok == true, "DM creates a private draft")
	expect(playerDraft ~= nil and playerDraft.ok == true, "player creates a private draft")
	expect(observerDraft ~= nil and observerDraft.skipped == true, "observer skips draft creation")
	if dmDraft ~= nil then
		staleRetries += dmDraft.staleRetries or 0
	end
	if playerDraft ~= nil then
		staleRetries += playerDraft.staleRetries or 0
	end
	local dmDraftId = if dmDraft ~= nil then dmDraft.draftId else nil
	local playerDraftId = if playerDraft ~= nil then playerDraft.draftId else nil
	expect(type(dmDraftId) == "string", "DM receives the created draft identity")
	expect(type(playerDraftId) == "string", "player receives the created draft identity")
	expect(dmDraftId ~= playerDraftId, "each owner receives a distinct draft")

	control:FireAllClients({
		phase = "inspect",
		dmDraftId = dmDraftId,
		playerDraftId = playerDraftId,
	})
	local inspected = waitForReports("inspect")
	expect(inspected, "all clients inspect their server projection")
	if not inspected then
		finish(staleRetries)
		return
	end
	local dmInspect = reportForRole("inspect", "dm")
	local playerInspect = reportForRole("inspect", "player")
	local observerInspect = reportForRole("inspect", "observer")
	expect(
		dmInspect ~= nil
			and dmInspect.hasDmDraft == true
			and dmInspect.hasPlayerDraft == true
			and dmInspect.dmPrivate == true
			and dmInspect.playerPrivate == true,
		"DM projection contains both full private drafts"
	)
	expect(
		dmInspect ~= nil and dmInspect.workspaceVisible == true,
		"DM projection contains the private workspace"
	)
	expect(
		playerInspect ~= nil
			and playerInspect.hasDmDraft == false
			and playerInspect.hasPlayerDraft == true
			and playerInspect.playerPrivate == true,
		"player projection contains only the owned private draft"
	)
	expect(
		playerInspect ~= nil and playerInspect.workspaceVisible == false,
		"player projection excludes the DM workspace"
	)
	expect(
		observerInspect ~= nil
			and observerInspect.hasDmDraft == false
			and observerInspect.hasPlayerDraft == false,
		"observer projection excludes all private drafts"
	)
	expect(
		observerInspect ~= nil and observerInspect.workspaceVisible == false,
		"observer projection excludes the DM workspace"
	)

	local player = playerForRole("player")
	expect(player ~= nil, "player client is available for connection transition checks")
	if player ~= nil then
		local testUserId = testUserIdByPlayer[player]
		local disconnected = runtime:executeSystem("session.connection", {
			userId = testUserId,
			status = "disconnected",
		})
		publisher:publishAll()
		local reconnected = runtime:executeSystem("session.connection", {
			userId = testUserId,
			status = "connected",
		})
		publisher:publishAll()
		expect(disconnected.ok and reconnected.ok, "disconnect and reconnect transitions commit")
		equal(
			runtime:snapshot().domains.session.connections[tostring(testUserId)],
			"connected",
			"reconnection restores connected session state"
		)
	end

	control:FireAllClients({ phase = "resync" })
	local resynced = waitForReports("resync")
	expect(resynced, "all clients finish the full-resync phase")
	if resynced then
		for _, role in ROLE_ORDER do
			local message = reportForRole("resync", role)
			expect(
				message ~= nil and message.sequenceIncreasing == true,
				role .. " projection sequence advances across full resyncs"
			)
			expect(
				message ~= nil and message.revisionStable == true,
				role .. " repeated full resync keeps the same revision"
			)
			expect(
				message ~= nil and message.epochStable == true,
				role .. " repeated full resync keeps the same authority epoch"
			)
		end
	end

	finish(staleRetries)
end)
