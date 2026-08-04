--!strict
local Helpers = require(script.Parent.DomainHelpers)
local Identity = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Identity)

local Domain = { id = "session", slice = 1 }
function Domain.initialState()
	return { campaignId = Identity.new("campaign", "default"), phase = "lobby", memberships = {}, ready = {}, selectedCharacter = {}, connections = {}, sceneId = nil }
end
function Domain.register(registry)
	registry:register({ commandType = "session.join", domainId = Domain.id, validate = function(p) return Helpers.hasString(p, "displayName") end, execute = function(c, s, p)
		s.memberships[tostring(c.playerId)] = { userId = c.playerId, displayName = p.displayName, role = c.role, joinedAt = os.time() }
		s.connections[tostring(c.playerId)] = "connected"
		return { membership = s.memberships[tostring(c.playerId)] }
	end })
	registry:register({ commandType = "session.select_character", domainId = Domain.id, validate = function(p) return Helpers.hasString(p, "characterId") end, execute = function(c, s, p)
		assert(s.memberships[tostring(c.playerId)] ~= nil, "membership required")
		s.selectedCharacter[tostring(c.playerId)] = p.characterId
		s.ready[tostring(c.playerId)] = false
		return { characterId = p.characterId }
	end })
	registry:register({ commandType = "session.ready", domainId = Domain.id, validate = function(p) return type(p.ready) == "boolean" end, execute = function(c, s, p)
		assert(s.selectedCharacter[tostring(c.playerId)] ~= nil, "character selection required")
		s.ready[tostring(c.playerId)] = p.ready
		return { ready = p.ready }
	end })
	registry:register({ commandType = "session.start", domainId = Domain.id, authorize = function(c) return Helpers.requireRole(c, { "dm" }) end, validate = function(p) return Helpers.hasString(p, "sceneId") end, execute = function(_, s, p)
		s.phase = "active"; s.sceneId = p.sceneId; return { phase = s.phase, sceneId = s.sceneId }
	end })
	registry:register({ commandType = "session.connection", domainId = Domain.id, validate = function(p) return p.status == "connected" or p.status == "disconnected" end, execute = function(c, s, p)
		s.connections[tostring(c.playerId)] = p.status; return { status = p.status }
	end })
end
return table.freeze(Domain)
