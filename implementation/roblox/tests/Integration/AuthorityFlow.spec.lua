--!strict

return function(harness)
    local Server = game:GetService("ServerScriptService").RVTT.Server
    local Registry = require(Server.Runtime.CommandRegistry).new()
    local Diagnostics = require(Server.Runtime.Diagnostics).new()
    local Outbox = require(Server.Runtime.EventOutbox).new()
    local Journal = require(Server.Persistence.SnapshotJournal).new(20)
    local Transactions = require(Server.Runtime.TransactionCoordinator).new(Diagnostics)
    local Runtime = require(Server.Runtime.AuthorityRuntime).new(Registry, Transactions, Outbox, Diagnostics, Journal)
    for _, domain in require(Server.Bootstrap.ServiceGraph).domainModules() do Runtime:installDomain(domain) end

    local context = {
        player = nil,
        playerId = 101,
        role = "player",
        origin = "remote",
        commandId = "command:join",
        correlationId = "command:join",
    }
    local result = Runtime:execute(context, {
        commandId = "command:join",
        commandType = "session.join",
        correlationId = "command:join",
        payload = {},
    })
    harness:expect(result.ok, "session join commits")
    harness:equal(Runtime:snapshot().revision, 1, "revision increments")

    local duplicate = Runtime:execute(context, {
        commandId = "command:join",
        commandType = "session.join",
        correlationId = "command:join",
        payload = {},
    })
    harness:expect(duplicate.ok, "duplicate returns the terminal result")
    harness:equal(Runtime:snapshot().revision, 1, "duplicate does not commit twice")
end
