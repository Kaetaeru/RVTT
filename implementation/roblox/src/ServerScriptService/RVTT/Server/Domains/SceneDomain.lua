--!strict
local Helpers = require(script.Parent.DomainHelpers)
local Domain = { id = "scene", slice = 1 }
function Domain.initialState() return { activeSceneId = nil, actors = {}, objects = {}, sceneRevision = 0 } end
function Domain.register(registry)
	registry:register({ commandType = "scene.enter", domainId = Domain.id, validate = function(p) return Helpers.hasString(p, "sceneId") and Helpers.hasString(p, "actorId") end, execute = function(c, s, p)
		s.activeSceneId = p.sceneId
		s.actors[p.actorId] = s.actors[p.actorId] or { id = p.actorId, ownerUserId = c.playerId, controllerUserId = c.playerId, position = { x = 0, y = 0, z = 0 }, incarnation = 1 }
		s.sceneRevision += 1
		return { actor = s.actors[p.actorId], sceneRevision = s.sceneRevision }
	end })
	registry:register({ commandType = "scene.spawn_object", domainId = Domain.id, authorize = function(c) return Helpers.requireRole(c, { "dm" }) end, validate = function(p) return Helpers.hasString(p, "objectId") and Helpers.hasString(p, "kind") end, execute = function(_, s, p)
		s.objects[p.objectId] = { id = p.objectId, kind = p.kind, state = p.state or {}, incarnation = 1 }
		s.sceneRevision += 1
		return s.objects[p.objectId]
	end })
end
return table.freeze(Domain)
