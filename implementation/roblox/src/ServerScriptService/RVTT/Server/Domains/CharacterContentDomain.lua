--!strict
local Helpers=require(script.Parent.DomainHelpers);local Domain={id="character_content",slice=13}
function Domain.initialState()return{catalogs={},coverage={},rightsStatus="blocked_until_review"}end
function Domain.register(registry)
	registry:register({commandType="character_content.register_catalog",domainId=Domain.id,authorize=function(c)return Helpers.requireRole(c,{"dm"})end,validate=function(p)return Helpers.hasString(p,"catalogId") and type(p.entries)=="table"end,execute=function(_,s,p)assert(p.rightsStatus=="approved" or p.rightsStatus=="original","rights approval required");s.catalogs[p.catalogId]={entries=p.entries,sourceVersion=p.sourceVersion,rightsStatus=p.rightsStatus};s.coverage[p.catalogId]=#p.entries;return s.catalogs[p.catalogId]end})
end
return table.freeze(Domain)
