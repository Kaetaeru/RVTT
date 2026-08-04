--!strict
local Helpers=require(script.Parent.DomainHelpers);local Domain={id="rules_content",slice=14}
function Domain.initialState()return{spells={},equipment={},conditions={},rightsStatus="blocked_until_review"}end
function Domain.register(registry)
	registry:register({commandType="rules_content.register",domainId=Domain.id,authorize=function(c)return Helpers.requireRole(c,{"dm"})end,validate=function(p)return Helpers.hasString(p,"kind") and type(p.entries)=="table"end,execute=function(_,s,p)assert(p.rightsStatus=="approved" or p.rightsStatus=="original","rights approval required");assert(s[p.kind]~=nil,"unsupported content kind");for id,entry in p.entries do s[p.kind][id]=entry end;return{kind=p.kind,count=(function()local n=0;for _ in p.entries do n+=1 end;return n end)()}end})
end
return table.freeze(Domain)
