--!strict
local Helpers = require(script.Parent.DomainHelpers)
local Domain = { id = "movement", slice = 1 }
local MAX_DISTANCE = 200
function Domain.initialState() return { positions = {}, executions = {}, checkpoints = {} } end
function Domain.register(registry)
	registry:register({ commandType = "movement.commit", domainId = Domain.id, validate = function(p)
		return Helpers.hasString(p, "actorId") and type(p.destination) == "table"
	end, execute = function(c, s, p)
		local d = p.destination
		assert(type(d.x) == "number" and type(d.y) == "number" and type(d.z) == "number", "invalid destination")
		local current = s.positions[p.actorId] or { x = d.x, y = d.y, z = d.z }
		local distance = math.sqrt((d.x-current.x)^2 + (d.y-current.y)^2 + (d.z-current.z)^2)
		assert(distance <= MAX_DISTANCE, "movement exceeds safety bound")
		local executionId = p.executionId or ("move:" .. c.commandId)
		s.executions[executionId] = { actorId = p.actorId, from = current, destination = d, status = "committed" }
		s.positions[p.actorId] = { x = d.x, y = d.y, z = d.z }
		table.insert(s.checkpoints, { executionId = executionId, position = s.positions[p.actorId] })
		return { executionId = executionId, position = s.positions[p.actorId], distance = distance }
	end })
end
return table.freeze(Domain)
