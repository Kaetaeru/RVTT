--!strict
local Helpers=require(script.Parent.DomainHelpers);local Identity=require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Identity);local Domain={id="npc_content",slice=15}
function Domain.initialState()return{definitions={},instances={}}end
function Domain.register(registry)
	local dm=function(c)return Helpers.requireRole(c,{"dm"})end
	registry:register({commandType="npc.register_definition",domainId=Domain.id,authorize=dm,validate=function(p)return Helpers.hasString(p,"definitionId") and type(p.definition)=="table"end,execute=function(_,s,p)assert(p.rightsStatus=="approved" or p.rightsStatus=="original","rights approval required");s.definitions[p.definitionId]=p.definition;return p.definition end})
	registry:register({commandType="npc.spawn",domainId=Domain.id,authorize=dm,validate=function(p)return Helpers.hasString(p,"definitionId")end,execute=function(_,s,p)local def=s.definitions[p.definitionId];assert(def,"definition required");local id=Identity.new("actor");s.instances[id]={id=id,definitionId=p.definitionId,sceneId=p.sceneId,position=p.position or{x=0,y=0,z=0},runtime=table.clone(def.runtime or{})};return s.instances[id]end})
end
return table.freeze(Domain)
