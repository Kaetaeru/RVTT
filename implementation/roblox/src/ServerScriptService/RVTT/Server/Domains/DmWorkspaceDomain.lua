--!strict
local Helpers=require(script.Parent.DomainHelpers);local Domain={id="dm_workspace",slice=11}
function Domain.initialState()return{control={},quickActions={},runtimePatches={},recoveryRequests={}}end
function Domain.register(registry)
	local dm=function(c)return Helpers.requireRole(c,{"dm"})end
	registry:register({commandType="dm.assign_control",domainId=Domain.id,authorize=dm,validate=function(p)return Helpers.hasString(p,"actorId") and type(p.controllerUserId)=="number"end,execute=function(_,s,p)s.control[p.actorId]=p.controllerUserId;return{actorId=p.actorId,controllerUserId=p.controllerUserId}end})
	registry:register({commandType="dm.quick_action",domainId=Domain.id,authorize=dm,validate=function(p)return Helpers.hasString(p,"actionId")end,execute=function(c,s,p)local record={actionId=p.actionId,payload=p.payload or{},commandId=c.commandId,createdAt=os.time()};table.insert(s.quickActions,record);return record end})
	registry:register({commandType="dm.runtime_patch",domainId=Domain.id,authorize=dm,validate=function(p)return Helpers.hasString(p,"targetId") and type(p.patch)=="table"end,execute=function(_,s,p)s.runtimePatches[p.targetId]={patch=p.patch,revision=(s.runtimePatches[p.targetId]and s.runtimePatches[p.targetId].revision or 0)+1};return s.runtimePatches[p.targetId]end})
	registry:register({commandType="dm.request_recovery",domainId=Domain.id,authorize=dm,execute=function(c,s,p)local id="recovery:"..c.commandId;s.recoveryRequests[id]={id=id,target=p.target,status="requested"};return s.recoveryRequests[id]end})
end
return table.freeze(Domain)
