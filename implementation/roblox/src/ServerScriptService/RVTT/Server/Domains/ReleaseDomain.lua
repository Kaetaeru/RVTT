--!strict
local Helpers=require(script.Parent.DomainHelpers);local Domain={id="release",slice=16}
local required={"unit","integration","roblox","migration","security","performance","soak","rollback"}
function Domain.initialState()return{evidence={},gate={status="blocked",missing=required}}end
local function evaluate(s)local missing={};for _,kind in required do local e=s.evidence[kind];if not e or e.status~="pass"then table.insert(missing,kind)end end;s.gate={status=(#missing==0 and"pass"or"blocked"),missing=missing,evaluatedAt=os.time()};return s.gate end
function Domain.register(registry)
	registry:register({commandType="release.record_evidence",domainId=Domain.id,authorize=function(c)return Helpers.requireRole(c,{"dm"})end,validate=function(p)return Helpers.hasString(p,"kind") and Helpers.hasString(p,"status")end,execute=function(_,s,p)s.evidence[p.kind]={status=p.status,reference=p.reference,recordedAt=os.time()};return evaluate(s)end})
	registry:register({commandType="release.evaluate",domainId=Domain.id,authorize=function(c)return Helpers.requireRole(c,{"dm"})end,execute=function(_,s,_)return evaluate(s)end})
end
return table.freeze(Domain)
