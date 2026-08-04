--!strict
local Helpers = require(script.Parent.DomainHelpers)
local Domain = { id = "exploration", slice = 3 }
function Domain.initialState() return { objectStates = {}, knowledge = {}, fog = {}, searches = {} } end
function Domain.register(registry)
	registry:register({ commandType = "exploration.interact", domainId = Domain.id, validate = function(p) return Helpers.hasString(p,"objectId") and Helpers.hasString(p,"interaction") end, execute = function(c,s,p)
		local object = s.objectStates[p.objectId] or { state = "idle", revision = 0 }
		object.state = p.interaction; object.revision += 1; object.lastActorUserId = c.playerId; s.objectStates[p.objectId]=object
		return { objectId=p.objectId, object=object }
	end })
	registry:register({ commandType = "exploration.search", domainId = Domain.id, validate = function(p) return Helpers.hasString(p,"scopeId") end, execute = function(c,s,p)
		local id="search:"..c.commandId; s.searches[id]={scopeId=p.scopeId,observerUserId=c.playerId,status="resolved",revealed=p.revealed or {}}
		for _, knowledgeId in p.revealed or {} do s.knowledge[tostring(c.playerId)..":"..knowledgeId]=true end
		return s.searches[id]
	end })
	registry:register({ commandType = "exploration.set_fog", domainId = Domain.id, authorize=function(c) return Helpers.requireRole(c,{"dm"}) end, validate=function(p) return Helpers.hasString(p,"regionId") and type(p.hidden)=="boolean" end, execute=function(_,s,p)
		s.fog[p.regionId]={hidden=p.hidden,revision=(s.fog[p.regionId] and s.fog[p.regionId].revision or 0)+1}; return s.fog[p.regionId]
	end })
end
return table.freeze(Domain)
