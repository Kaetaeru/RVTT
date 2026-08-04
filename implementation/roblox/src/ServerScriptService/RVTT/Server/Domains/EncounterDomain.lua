--!strict
local Helpers = require(script.Parent.DomainHelpers)
local Domain = { id = "encounter", slice = 4 }
function Domain.initialState() return { active=nil, checkpoints={}, history={} } end
function Domain.register(registry)
	registry:register({ commandType="encounter.start",domainId=Domain.id,authorize=function(c)return Helpers.requireRole(c,{"dm"})end,validate=function(p)return type(p.participants)=="table"end,execute=function(c,s,p)
		assert(s.active==nil,"encounter already active"); local timeline={}; for i,id in p.participants do table.insert(timeline,{id=id,initiative=(p.initiative and p.initiative[id]) or (100-i)}) end; table.sort(timeline,function(a,b)return a.initiative>b.initiative end)
		s.active={id=p.encounterId or ("encounter:"..c.commandId),round=1,cursor=1,timeline=timeline,opportunities={},status="active"}; table.insert(s.checkpoints,{round=1,cursor=1,snapshot=table.clone(s.active)}); return s.active
	end })
	registry:register({ commandType="encounter.end_turn",domainId=Domain.id,execute=function(_,s,_)
		assert(s.active~=nil,"encounter required"); s.active.cursor+=1; if s.active.cursor>#s.active.timeline then s.active.cursor=1; s.active.round+=1 end; table.insert(s.history,{kind="turn_end",round=s.active.round,cursor=s.active.cursor}); table.insert(s.checkpoints,{round=s.active.round,cursor=s.active.cursor,snapshot=table.clone(s.active)}); return s.active
	end })
	registry:register({ commandType="encounter.end",domainId=Domain.id,authorize=function(c)return Helpers.requireRole(c,{"dm"})end,execute=function(_,s,p)
		assert(s.active~=nil,"encounter required"); s.active.status="ended"; s.active.reason=p.reason or "dm"; local ended=s.active; s.active=nil; return ended
	end })
	registry:register({ commandType="encounter.rollback",domainId=Domain.id,authorize=function(c)return Helpers.requireRole(c,{"dm"})end,validate=function(p)return type(p.checkpointIndex)=="number"end,execute=function(_,s,p)
		local checkpoint=s.checkpoints[p.checkpointIndex]; assert(checkpoint~=nil,"checkpoint not found"); s.active=table.clone(checkpoint.snapshot); table.insert(s.history,{kind="rollback",checkpointIndex=p.checkpointIndex}); return s.active
	end })
end
return table.freeze(Domain)
