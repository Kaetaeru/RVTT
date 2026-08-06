--!strict

return function(harness: any)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local AccentPreference = require(ReplicatedStorage.RVTT.Shared.UI.AccentPreference)
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local Registry = require(Server.Runtime.CommandRegistry).new()
	local Diagnostics = require(Server.Runtime.Diagnostics).new()
	local Outbox = require(Server.Runtime.EventOutbox).new()
	local Journal = require(Server.Persistence.SnapshotJournal).new(20)
	local Transactions = require(Server.Runtime.TransactionCoordinator).new(Diagnostics)
	local Runtime = require(Server.Runtime.AuthorityRuntime).new(
		Registry,
		Transactions,
		Outbox,
		Diagnostics,
		Journal
	)
	for _, domain in require(Server.Bootstrap.ServiceGraph).domainModules() do
		Runtime:installDomain(domain)
	end

	local function execute(playerId: number, commandId: string, key: string, value: any): any
		return Runtime:execute({
			player = { DisplayName = "Preference Tester" },
			playerId = playerId,
			role = "player",
			origin = "remote",
			commandId = commandId,
			correlationId = commandId,
		}, {
			commandId = commandId,
			commandType = "ui.set_preference",
			correlationId = commandId,
			payload = { key = key, value = value },
		})
	end

	local first = execute(101, "command:accent:101", AccentPreference.KEY, "azure")
	harness:expect(first.ok, "authenticated user can store an allowed accent")
	harness:equal(
		Runtime:snapshot().domains.ui_preferences.byUser["101"][AccentPreference.KEY],
		"azure",
		"accent is stored under the authenticated user"
	)

	local previousRevision = Runtime:snapshot().revision
	local invalid = execute(101, "command:accent:invalid", AccentPreference.KEY, "hot-pink")
	harness:expect(not invalid.ok, "unreviewed accent is rejected")
	harness:equal(
		Runtime:snapshot().revision,
		previousRevision,
		"invalid accent does not commit a new revision"
	)

	local existingPreference = execute(101, "command:scale:101", "uiScale", 1.2)
	harness:expect(existingPreference.ok, "existing UI preferences remain supported")

	local second = execute(202, "command:accent:202", AccentPreference.KEY, "emerald")
	harness:expect(second.ok, "another user can store an independent accent")

	local Builder = require(Server.Projection.ProjectionBuilder).new()
	local firstProjection = Builder:build(Runtime:snapshot(), 101, "player")
	local firstByUser = firstProjection.payload.domains.ui_preferences.byUser
	local firstPreferences: any = firstByUser["101"]
	harness:equal(
		firstPreferences[AccentPreference.KEY],
		"azure",
		"viewer receives the authoritative accent"
	)
	harness:equal(firstPreferences.uiScale, 1.2, "viewer receives existing UI preferences")
	harness:expect(firstByUser["202"] == nil, "viewer does not receive another user's preferences")

	local secondProjection = Builder:build(Runtime:snapshot(), 202, "player")
	local secondByUser = secondProjection.payload.domains.ui_preferences.byUser
	local secondPreferences: any = secondByUser["202"]
	harness:equal(
		secondPreferences[AccentPreference.KEY],
		"emerald",
		"second viewer receives only its own accent"
	)
	harness:expect(
		secondByUser["101"] == nil,
		"second viewer cannot inspect first viewer preferences"
	)
end
