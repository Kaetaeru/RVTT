--!strict
local Helpers=require(script.Parent.DomainHelpers);local Identity=require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Identity);local Domain={id="scene_authoring",slice=10}
function Domain.initialState()return{sources={},candidates={},published={}}end
function Domain.register(registry)
	local dm=function(c)return Helpers.requireRole(c,{"dm"})end
	registry:register({commandType="authoring.create_scene",domainId=Domain.id,authorize=dm,execute=function(_,s,p)local id=Identity.new("scene");s.sources[id]={id=id,name=p.name or"",objects={},revision=1};return s.sources[id]end})
	registry:register({commandType="authoring.upsert_object",domainId=Domain.id,authorize=dm,validate=function(p)return Helpers.hasString(p,"sceneId") and type(p.object)=="table"end,execute=function(_,s,p)local scene=s.sources[p.sceneId];assert(scene,"scene required");local objectId=p.object.id or Identity.new("object");p.object.id=objectId;scene.objects[objectId]=p.object;scene.revision+=1;return p.object end})
	registry:register({commandType="authoring.compile",domainId=Domain.id,authorize=dm,validate=function(p)return Helpers.hasString(p,"sceneId")end,execute=function(_,s,p)local source=s.sources[p.sceneId];assert(source,"scene required");s.candidates[p.sceneId]={sourceRevision=source.revision,compiledAt=os.time(),objects=source.objects,valid=true};return s.candidates[p.sceneId]end})
	registry:register({commandType="authoring.publish",domainId=Domain.id,authorize=dm,validate=function(p)return Helpers.hasString(p,"sceneId")end,execute=function(_,s,p)local candidate=s.candidates[p.sceneId];assert(candidate and candidate.valid,"valid candidate required");s.published[p.sceneId]=candidate;return candidate end})
end
return table.freeze(Domain)
