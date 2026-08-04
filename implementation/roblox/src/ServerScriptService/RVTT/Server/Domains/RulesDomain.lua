--!strict
local Helpers = require(script.Parent.DomainHelpers)
local Dice = require(game:GetService("ReplicatedStorage").RVTT.Shared.Rules.Dice)
local Ability = require(game:GetService("ReplicatedStorage").RVTT.Shared.Rules.Ability)
local Domain = { id = "rules", slice = 2 }
function Domain.initialState() return { rollRecords = {}, hitPoints = {}, resources = {}, conditions = {} } end
local function record(s, c, kind, data)
	local id = "roll:" .. c.commandId
	s.rollRecords[id] = { id = id, kind = kind, data = data, createdAt = os.time() }
	return s.rollRecords[id]
end
function Domain.register(registry)
	registry:register({ commandType = "rules.ability_check", domainId = Domain.id, validate = function(p) return Helpers.hasNumber(p, "modifier") and Helpers.hasNumber(p, "dc") end, execute = function(c,s,p)
		local natural, rolls = Dice.rollD20(p.mode); local total = natural + p.modifier
		return record(s,c,"ability_check",{ natural=natural, rolls=rolls, total=total, dc=p.dc, success=Ability.test(total,p.dc) })
	end })
	registry:register({ commandType = "rules.attack", domainId = Domain.id, validate = function(p) return Helpers.hasNumber(p,"attackBonus") and Helpers.hasNumber(p,"armorClass") end, execute = function(c,s,p)
		local natural, rolls = Dice.rollD20(p.mode); local total = natural + p.attackBonus
		local hit = natural == 20 or (natural ~= 1 and total >= p.armorClass)
		return record(s,c,"attack",{ natural=natural, rolls=rolls, total=total, hit=hit, critical=natural==20 })
	end })
	registry:register({ commandType = "rules.apply_damage", domainId = Domain.id, validate = function(p) return Helpers.hasString(p,"targetId") and Helpers.hasNumber(p,"amount") end, execute = function(_,s,p)
		local current = s.hitPoints[p.targetId] or { current = p.maximum or 1, maximum = p.maximum or 1, temporary = 0 }
		local amount = math.max(0, math.floor(p.amount)); local absorbed = math.min(current.temporary, amount)
		current.temporary -= absorbed; current.current = math.max(0, current.current - (amount - absorbed)); s.hitPoints[p.targetId] = current
		return { targetId=p.targetId, hitPoints=current, applied=amount }
	end })
	registry:register({ commandType = "rules.apply_healing", domainId = Domain.id, validate = function(p) return Helpers.hasString(p,"targetId") and Helpers.hasNumber(p,"amount") end, execute = function(_,s,p)
		local current = s.hitPoints[p.targetId] or { current = 0, maximum = p.maximum or 1, temporary = 0 }
		current.current = math.min(current.maximum, current.current + math.max(0, math.floor(p.amount))); s.hitPoints[p.targetId] = current
		return { targetId=p.targetId, hitPoints=current }
	end })
end
return table.freeze(Domain)
