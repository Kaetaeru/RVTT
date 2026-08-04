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
        playerId = 222,
        role = "player",
        origin = "remote",
        commandId = "command:attack",
        correlationId = "command:attack",
    }
    local attack = Runtime:execute(context, {
        commandId = "command:attack",
        commandType = "rules.attack",
        correlationId = "command:attack",
        payload = {
            attackerId = "actor:not-owned",
            targetId = "actor:target",
            profileId = "attack.unarmed",
            attackBonus = 999,
            armorClass = 1,
            damage = 999,
        },
    })
    harness:expect(not attack.ok, "client cannot inject rule authority values")
    harness:equal(Runtime:snapshot().revision, 0, "unauthorized attack does not commit")

    local connection = Runtime:execute(context, {
        commandId = "command:connection",
        commandType = "session.connection",
        correlationId = "command:connection",
        payload = { userId = 222, status = "connected" },
    })
    harness:expect(not connection.ok, "remote client cannot invoke system-only command")
end
