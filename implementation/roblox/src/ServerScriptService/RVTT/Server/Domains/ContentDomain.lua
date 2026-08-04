--!strict
local Helpers=require(script.Parent.DomainHelpers);local Domain={id="content",slice=12}
function Domain.initialState()return{packs={},active={},localization={}}end
function Domain.register(registry)
	local dm=function(c)return Helpers.requireRole(c,{"dm"})end
	registry:register({commandType="content.register_pack",domainId=Domain.id,authorize=dm,validate=function(p)return type(p.manifest)=="table" and Helpers.hasString(p.manifest,"packId")end,execute=function(_,s,p)local m=p.manifest;assert(s.packs[m.packId]==nil,"pack already registered");s.packs[m.packId]=m;return m end})
	registry:register({commandType="content.activate_pack",domainId=Domain.id,authorize=dm,validate=function(p)return Helpers.hasString(p,"packId")end,execute=function(_,s,p)local pack=s.packs[p.packId];assert(pack,"pack required");assert(pack.rightsStatus~="blocked","pack rights blocked");s.active[p.packId]=pack.version;return{packId=p.packId,version=pack.version}end})
	registry:register({commandType="content.localization",domainId=Domain.id,authorize=dm,validate=function(p)return Helpers.hasString(p,"locale") and type(p.entries)=="table"end,execute=function(_,s,p)s.localization[p.locale]=p.entries;return{locale=p.locale,count=(function()local n=0;for _ in p.entries do n+=1 end;return n end)()}end})
end
return table.freeze(Domain)
