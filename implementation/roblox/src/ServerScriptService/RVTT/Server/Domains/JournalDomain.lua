--!strict
local Helpers=require(script.Parent.DomainHelpers);local Identity=require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Identity);local Domain={id="journal",slice=9}
function Domain.initialState()return{documents={},pings={}}end
function Domain.register(registry)
	registry:register({commandType="journal.create",domainId=Domain.id,execute=function(c,s,p)local id=Identity.new("journal");s.documents[id]={id=id,ownerUserId=c.playerId,title=p.title or"",body=p.body or"",links={},revision=1,visibility=p.visibility or"private"};return s.documents[id]end})
	registry:register({commandType="journal.edit",domainId=Domain.id,validate=function(p)return Helpers.hasString(p,"documentId")end,execute=function(c,s,p)local d=s.documents[p.documentId];assert(d and(d.ownerUserId==c.playerId or c.role=="dm"),"journal permission required");d.title=p.title or d.title;d.body=p.body or d.body;d.links=p.links or d.links;d.revision+=1;return d end})
	registry:register({commandType="journal.ping",domainId=Domain.id,validate=function(p)return type(p.position)=="table"end,execute=function(c,s,p)local id=Identity.new("ping");s.pings[id]={id=id,userId=c.playerId,position=p.position,label=p.label,expiresAt=os.time()+30};return s.pings[id]end})
end
return table.freeze(Domain)
