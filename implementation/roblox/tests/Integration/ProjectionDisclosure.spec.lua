--!strict

return function(harness)
    local Server = game:GetService("ServerScriptService").RVTT.Server
    local Builder = require(Server.Projection.ProjectionBuilder).new()
    local state = {
        schemaVersion = 1,
        authorityEpoch = "epoch:test",
        revision = 1,
        domains = {
            character = {
                drafts = {},
                characters = {
                    owned = { id = "owned", ownerUserId = 1, name = "Owned", level = 1, abilities = { strength = 18 }, status = "active" },
                    other = { id = "other", ownerUserId = 2, name = "Other", level = 2, abilities = { strength = 20 }, status = "active" },
                },
            },
            dm_workspace = { recoveryRequests = { secret = { target = "hidden" } } },
        },
    }
    local projection = Builder:build(state, 1, "player")
    harness:expect(projection.payload.domains.dm_workspace.secret == nil, "DM workspace is not disclosed")
    harness:expect(projection.payload.domains.character.characters.owned.abilities ~= nil, "owner receives full character")
    harness:expect(projection.payload.domains.character.characters.other.abilities == nil, "other character is summarized")
end
