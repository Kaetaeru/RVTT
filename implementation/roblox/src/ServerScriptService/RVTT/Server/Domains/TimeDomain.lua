--!strict
local Helpers=require(script.Parent.DomainHelpers);local Domain={id="time",slice=7}
function Domain.initialState()return{campaignSeconds=0,schedules={},activities={}}end
function Domain.register(registry)
	registry:register({commandType="time.advance",domainId=Domain.id,authorize=function(c)return Helpers.requireRole(c,{"dm"})end,validate=function(p)return type(p.seconds)=="number" and p.seconds>=0 end,execute=function(_,s,p)s.campaignSeconds+=math.floor(p.seconds);local due={};for id,item in s.schedules do if item.dueAt<=s.campaignSeconds and item.status=="scheduled"then item.status="due";table.insert(due,id)end end;return{campaignSeconds=s.campaignSeconds,due=due}end})
	registry:register({commandType="time.schedule",domainId=Domain.id,validate=function(p)return Helpers.hasString(p,"scheduleId") and type(p.afterSeconds)=="number"end,execute=function(_,s,p)s.schedules[p.scheduleId]={dueAt=s.campaignSeconds+math.max(0,math.floor(p.afterSeconds)),payload=p.payload or{},status="scheduled"};return s.schedules[p.scheduleId]end})
	registry:register({commandType="time.activity",domainId=Domain.id,validate=function(p)return Helpers.hasString(p,"activityId") and Helpers.hasString(p,"kind")end,execute=function(c,s,p)s.activities[p.activityId]={kind=p.kind,ownerUserId=c.playerId,status=p.status or"started",startedAt=s.campaignSeconds};return s.activities[p.activityId]end})
end
return table.freeze(Domain)
